class SlackAppSMConnection : Connection {
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
        $token_app = $this.Config.CredentialApp.GetNetworkCredential().Password  # xapp...
        $token_bot = $this.Config.Credential.GetNetworkCredential().Password     # xoxb...

        # https://api.slack.com/apis/socket-mode
        $url = 'https://slack.com/api/apps.connections.open'

        try {

            $r = Invoke-RestMethod -Method POST -Uri $url -Verbose:$false -Headers @{
                'Content-type' = 'application/x-www-form-urlencoded'
                Authorization  = "Bearer $token_app"
            }

            $rb = Invoke-RestMethod -Method POST -Uri 'https://slack.com/api/auth.test?pretty=1' -Verbose:$false -Headers @{
                'Content-type' = 'application/x-www-form-urlencoded'
                Authorization  = "Bearer $token_bot"
            }

            $rc = Invoke-RestMethod -Method GET -Uri 'https://slack.com/api/conversations.list' -Headers @{
                'Content-type' = 'application/x-www-form-urlencoded'
                Authorization  = "Bearer $token_bot"
            }

            $this.LoginData = [PsCustomObject]@{
                channels = $rc.channels
                self     = [PsCustomObject]@{
                    id = $rb.user_id
                }
            }

            if ($r.ok) {
                $this.LogInfo('Successfully authenticated to Slack Real Time API')
                $this.WebSocketUrl = $r.url
                $this.Domain = $rb.team   # .team.domain
                $this.UserName = $rb.user # .self.name
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
            $pingIntervalSeconds = 10
            $lastMsgId = 0

            $InformationPreference = 'Continue'
            $VerbosePreference = 'Continue'
            $DebugPreference = 'Continue'
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
            $redactedUrl = "$(Split-Path $url -Parent)\REDACTED"
            Write-Verbose "Connecting to websocket at [$($redactedUrl)]"
            if ($PSVersionTable.PSVersion.Major -lt 6) {
                # In PowerShell 5.1 (and probably 5.0), there is a bug where the websocket conenction will disconenct after 100 seconds
                # The workaround is to change the keepalive internval to 0 OR adjust the max service point idel time
                # https://stackoverflow.com/questions/40502921/net-websockets-forcibly-closed-despite-keep-alive-and-activity-on-the-connectio
                Write-Verbose "PowerShell version is [$($PSVersionTable.PSVersion.ToString())]. Setting [System.Net.ServicePointManager]::MaxServicePointIdleTime to [$([int]::MaxValue.ToString())] to avoid disconnects at 100 seconds."
                [System.Net.ServicePointManager]::MaxServicePointIdleTime = [Int]::MaxValue
            }
            $webSocket = [Net.WebSockets.ClientWebSocket]::new()
            $webSocket.Options.KeepAliveInterval = 5
            $cts = [Threading.CancellationTokenSource]::new()
            $task = $webSocket.ConnectAsync($url, $cts.Token)
            do { [Threading.Thread]::Sleep(10) }
            until ($task.IsCompleted)

            # Receive messages and put on output stream so the backend can read them
            $buffer = [Net.WebSockets.WebSocket]::CreateClientBuffer(1024,1024)
            $ct = [Threading.CancellationToken]::new($false)
            $taskResult = $null

            Write-Verbose 'Beginning websocker receive loop'
            while ($webSocket.State -eq [Net.WebSockets.WebSocketState]::Open) {
                $jsonResult = ''
                do {
                    $taskResult = $webSocket.ReceiveAsync($buffer, $ct)
                    while (-not $taskResult.IsCompleted -and $webSocket.State -eq [Net.WebSockets.WebSocketState]::Open) {
                        [Threading.Thread]::Sleep(10)

                        # Send "ping" every 5 seconds
                        if ($stopWatch.Elapsed.Seconds -ge $pingIntervalSeconds) {
                            Send-Ping
                            $stopWatch.Restart()
                        }
                    }

                    if ($webSocket.State -ne [Net.WebSockets.WebSocketState]::Open) {
                        Write-Error "Websocket error. Connection state is [$($webSocket.State)]"
                    }

                    $jsonResult += [Text.Encoding]::UTF8.GetString($buffer, 0, $taskResult.Result.Count)
                } until (
                    $webSocket.State -ne [Net.WebSockets.WebSocketState]::Open -or $taskResult.Result.EndOfMessage
                )


                if (-not [string]::IsNullOrEmpty($jsonResult)) {

                    #region acknowledgment
                    # Prepare the acknowledgment message
                    $ackPayload = @{
                        envelope_id = ($jsonResult | ConvertFrom-Json).envelope_id
                    } | ConvertTo-Json

                    # Convert the message to bytes
                    $ackBytes = [System.Text.Encoding]::UTF8.GetBytes($ackPayload)

                    # Send the acknowledgment
                    $sendBuffer = [ArraySegment[byte]]$ackBytes
                    # Send - v1
                    # $sendTask = $webSocket.SendAsync($sendBuffer, [Net.WebSockets.WebSocketMessageType]::Text, $true, $ct)
                    # $sendTask.Wait()

                    # Send - v2
                    $webSocket.SendAsync($sendBuffer, [Net.WebSockets.WebSocketMessageType]::Text, $true, $ct).GetAwaiter().GetResult() > $null

                    #endregion acknowledgment


                    #region get messages
                    $sanitizedJson = SanitizeURIs -Text $jsonResult

                    $msgs = ConvertFrom-Json $sanitizedJson | ForEach-Object {
                        $msgRawData = $null ; $msgRawData = $_
                        switch ($msgRawData.type) {
                            'slash_commands' {
                                $msgRawData | Select-Object -ExpandProperty payload | Select-Object @{N = 'user';E = { $_.user_id } },@{N = 'type';E = { 'message' } },@{N = 'text';E = { ($_.command -replace '\\\/','!' -replace '\/','!') + ' ' + ($_.text) } },@{N = 'slash_command_text';E = { $_.text } },@{N = 'team';E = { $_.team_id } },@{N = 'channel';E = { $_.channel_id } },@{N = 'channel_type';E = { 'im' } }
                            }
                            default {
                                $msgRawData | Select-Object -ExpandProperty payload | Select-Object -ExpandProperty event
                            }
                        }
                    }

                    foreach ($msg in $msgs) {
                        # Ingore "pong" and "hello" messages as they aren't important to the backend
                        if ($msg.type -ne 'pong' -and $msg.type -ne 'hello') {
                            $msg
                        }
                    }
                    #endregion get messages

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
        $infoStream = $this.ReceiveJob.ChildJobs[0].Information.ReadAll()
        $warningStream = $this.ReceiveJob.ChildJobs[0].Warning.ReadAll()
        $errStream = $this.ReceiveJob.ChildJobs[0].Error.ReadAll()
        $verboseStream = $this.ReceiveJob.ChildJobs[0].Verbose.ReadAll()
        $debugStream = $this.ReceiveJob.ChildJobs[0].Debug.ReadAll()
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
            $this.LogVerbose($item.ToString())
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
