class SlackConnection : Connection {
    [pscustomobject]$LoginData
    [string]$UserName
    [string]$Domain
    [string]$WebSocketUrl
    [bool]$Connected
    [object]$ReceiveJob = $null

    [void]Connect() {
        if ($null -eq $this.ReceiveJob -or $this.ReceiveJob.State -ne 'Running') {
            $this.LogDebug('Connecting to Slack Real Time API')
            $this.RtmConnect()
            $this.StartReceiveJob()
        } else {
            $this.LogDebug([LogSeverity]::Warning, 'Receive job is already running')
        }
    }

    # Log in to Slack with the bot token and get a URL to connect to via websockets
    [void]RtmConnect() {
        $token = $this.Config.Credential.GetNetworkCredential().Password
        $url = "https://slack.com/api/rtm.connect?token=$($token)&pretty=1"

        try {
            $r = Invoke-RestMethod -Uri $url -Method Get -Verbose:$false
            $this.LoginData = $r
            if ($r.ok) {
                $this.LogInfo('Successfully authenticated to Slack Real Time API')
                $this.WebSocketUrl = $r.url
                $this.Domain       = $r.team.domain
                $this.UserName     = $r.self.name
            } else {
                throw $r
            }
        } catch {
            $this.LogInfo([LogSeverity]::Error, 'Error connecting to Slack Real Time API', [ExceptionFormatter]::Summarize($_))
        }
    }

    # Setup the websocket receive job
    [void]StartReceiveJob() {
        $recv = {
            [cmdletbinding()]
            param(
                [parameter(mandatory)]
                $url
            )

            # To keep track of ping messages
            $lastMsgId = 0

            $InformationPreference = 'Continue'
            $VerbosePreference     = 'Continue'
            $DebugPreference       = 'Continue'
            $ErrorActionPreference = 'Continue'

            # Timer for sending pings
            $stopWatch = [Diagnostics.Stopwatch]::new()
            $stopWatch.Start()

            # Remove extra characters that Slack decorates urls with
            function SanitizeURIs {
                param(
                    [Parameter(mandatory)]
                    [string]$Text
                )

                $sanitizedText = $Text -replace '<([^\|>]+)\|([^\|>]+)>', '$2'
                $sanitizedText = $sanitizedText -replace '<(http([^>]+))>', '$1'
                $sanitizedText
            }

            # Messages sent via RTM should have a unique, incrementing ID
            # https://api.slack.com/rtm
            function Get-NextMsgId {
                $script:lastMsgId += 1
                $script:lastMsgId
            }

            function Send-Ping() {
                $json = @{
                    id   = Get-NextMsgId
                    type = 'ping'
                } | ConvertTo-Json

                [ArraySegment[byte]]$bytes = [Text.Encoding]::UTF8.GetBytes($json)
                $webSocket.SendAsync($bytes, [Net.WebSockets.WebSocketMessageType]::Text, $true, $ct).GetAwaiter().GetResult() > $null
            }

            # Slack enforces TLS12 on the websocket API
            [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

            # Connect to websocket
            Write-Verbose "[SlackBackend:ReceiveJob] Connecting to websocket at [$($url)]"
            $webSocket = [Net.WebSockets.ClientWebSocket]::new()
            $webSocket.Options.KeepAliveInterval = 5
            $cts  = [Threading.CancellationTokenSource]::new()
            $task = $webSocket.ConnectAsync($url, $cts.Token)
            do { [Threading.Thread]::Sleep(10) }
            until ($task.IsCompleted)

            # Receive messages and put on output stream so the backend can read them
            $buffer     = [Net.WebSockets.WebSocket]::CreateClientBuffer(1024,1024)
            $ct         = [Threading.CancellationToken]::new($false)
            $taskResult = $null

            Write-Verbose '[SlackBackend:ReceiveJob] Beginning websocker receive loop'
            while ($webSocket.State -eq [Net.WebSockets.WebSocketState]::Open) {
                $jsonResult = ""
                do {
                    $taskResult = $webSocket.ReceiveAsync($buffer, $ct)
                    while (-not $taskResult.IsCompleted) {
                        [Threading.Thread]::Sleep(10)

                        # Send "ping" every 5 seconds
                        if ($stopWatch.ElapsedMilliseconds -ge 5000) {
                            Send-Ping
                            $stopWatch.Restart()
                        }
                    }
                    $jsonResult += [Text.Encoding]::UTF8.GetString($buffer, 0, $taskResult.Result.Count)
                } until (
                    $taskResult.Result.EndOfMessage
                )

                if (-not [string]::IsNullOrEmpty($jsonResult)) {
                    # Write-Debug "Received JSON: $jsonResult"
                    $sanitizedJson = SanitizeURIs -Text $jsonResult

                    $msgs = ConvertFrom-Json $sanitizedJson
                    foreach ($msg in $msgs) {
                        if ($msg.type -ne 'pong' -and $msg.type -ne 'hello') {
                            $msg
                        }
                    }
                }
            }

            $socketStatus = [pscustomobject]@{
                State                  = $webSocket.State
                CloseStatus            = $webSocket.CloseStatus
                CloseStatusDescription = $webSocket.CloseStatusDescription
            }
            $socketStatusStr = ($socketStatus | Format-List | Out-String).Trim()
            Write-Warning -Message "Websocket state is [$($webSocket.State.ToString())].`n$socketStatusStr"
        }

        try {
            $jobParams = @{
                Name         = 'ReceiveRtmMessages'
                ScriptBlock  = $recv
                ArgumentList = $this.WebSocketUrl
            }
            $this.ReceiveJob = Start-Job @jobParams
            $this.Connected = $true
            $this.Status = [ConnectionStatus]::Connected
            $this.LogInfo("Started websocket receive job [$($this.ReceiveJob.Id)]")
        } catch {
            $this.LogInfo([LogSeverity]::Error, "$($_.Exception.Message)", [ExceptionFormatter]::Summarize($_))
        }
    }

    # Read all available data from the job
    [System.Collections.Generic.List[PSCustomObject]]ReadReceiveJob() {
        # Read stream info from the job so we can log them
        $infoStream     = $this.ReceiveJob.ChildJobs[0].Information.ReadAll()
        $warningStream  = $this.ReceiveJob.ChildJobs[0].Warning.ReadAll()
        $errStream      = $this.ReceiveJob.ChildJobs[0].Error.ReadAll()
        $verboseStream  = $this.ReceiveJob.ChildJobs[0].Verbose.ReadAll()
        $debugStream    = $this.ReceiveJob.ChildJobs[0].Debug.ReadAll()
        foreach ($item in $infoStream) {
            $this.LogInfo($item.ToString())
        }
        foreach ($item in $warningStream) {
            $this.LogInfo([LogSeverity]::Warning, $item.ToString())
        }
        foreach ($item in $errStream) {
            $this.LogInfo([LogSeverity]::Error, $item.ToString())
        }
        foreach ($item in $verboseStream) {
            $this.LogVerbose("I'm here: $($item.ToString())")
        }
        foreach ($item in $debugStream) {
            $this.LogVerbose($item.ToString())
        }

        # The receive job stopped for some reason. Reestablish the connection if the job isn't running
        if ($this.ReceiveJob.State -ne 'Running') {
            $this.LogInfo([LogSeverity]::Warning, "Receive job state is [$($this.ReceiveJob.State)]. Attempting to reconnect...")
            $this.Reconnect()
        }

        $messages = [Collections.Generic.List[PSCustomObject]]::new()
        if ($this.ReceiveJob.HasMoreData) {
            $messages.AddRange($this.ReceiveJob.ChildJobs[0].Output.ReadAll())
        }
        return $messages
    }

    # Stop the receive thread
    [void]Disconnect() {
        $this.LogInfo('Closing websocket')
        if ($this.ReceiveJob) {
            $this.LogInfo("Stopping receive job [$($this.ReceiveJob.Id)]")
            $this.ReceiveJob | Stop-Job -Confirm:$false -PassThru | Remove-Job -Force -ErrorAction SilentlyContinue
        }
        $this.Connected = $false
        $this.Status = [ConnectionStatus]::Disconnected
    }

    [void]Reconnect() {
        $this.Disconnect()
        Start-Sleep -Seconds 5
        $this.Connect()
    }
}
