class DiscordConnection : Connection {

    [Net.WebSockets.ClientWebSocket]$WebSocket
    [pscustomobject]$GatewayInfo
    [string]$GatewayUrl
    [bool]$Connected
    [object]$ReceiveJob = $null

    DiscordConnection() {
        $this.WebSocket = [Net.WebSockets.ClientWebSocket]::new()
        $this.WebSocket.Options.KeepAliveInterval = 5
    }

    # Connect to Discord and start receiving messages
    [void]Connect() {
        if ($null -eq $this.ReceiveJob -or $this.ReceiveJob.State -ne 'Running') {
            $this.LogDebug('Connection to Discord gateway')
            $this.ConnectGateway()
            $this.StartReceiveJob()
        } else {
            $this.LogDebug([LogSeverity]::Warning, 'Receive job is already running')
        }
    }

    # Log into Discord with the bot token
    [void]ConnectGateway() {
        try {
            $headers = @{
                Authorization = "Bot $($this.Config.Credential.GetNetworkCredential().password)"
            }
            $this.GatewayInfo = Invoke-RestMethod -Uri 'https://discordapp.com/api/gateway/bot' -Headers $headers
            $this.GatewayUrl = "$($this.GatewayInfo.url)/v=6&encoding=json"
        } catch {
            $this.LogInfo([LogSeverity]::Error, 'Unable to determine Discord gateway URL', [ExceptionFormatter]::Summarize($_))
        }
    }

    # Setup the websocket receive job
    [void]StartReceiveJob() {
        $recv = {
            [cmdletbinding()]
            param(
                [parameter(Mandatory)]
                [string]$Url,

                [string]$Token,

                [string]$BotId
            )

            $ErrorActionPreference = 'Stop'

            # https://discordapp.com/developers/docs/topics/opcodes-and-status-codes#gateway-opcodes
            enum DiscordOpCode {
                Dispatch            = 0
                Heartbeat           = 1
                Identify            = 2
                StatusUpdate        = 3
                VoiceStateUpdate    = 4
                # 5 is missing on purpose
                Resume              = 6
                Reconnect           = 7
                RequestGuildMembers = 8
                InvalidSession      = 9
                Hello               = 10
                HeartbeatAck        = 11
            }

            [Net.WebSockets.ClientWebSocket]$WebSocket = [Net.WebSockets.ClientWebSocket]::new()
            [int]$heartbeatInterval     = $null
            [int]$heartbeatSequence     = 0

            # Connect to websocket
            [ArraySegment[byte]]$buffer = [byte[]]::new(1024)
            $cts = [Threading.CancellationTokenSource]::new()
            $task = $webSocket.ConnectAsync($Url, $cts.Token)
            do { Start-Sleep -Milliseconds 100 }
            until ($task.IsCompleted)

            #[ArraySegment[byte]]$buffer = [byte[]]::new(100000)
            $ct = [Threading.CancellationToken]::new($false)
            $taskResult = $null

            function New-DiscordPayload {
                [OutputType([string])]
                [cmdletbinding()]
                param(
                    [parameter(Mandatory)]
                    [DiscordOpCode]$Opcode,

                    [parameter(Mandatory)]
                    [pscustomobject]$Data,

                    [int]$SequenceNumber,

                    [string]$EventName
                )

                $payload = @{
                    op = $Opcode.value__
                    d  = $Data
                }

                if ($Opcode -eq [DiscordOpCode]::Dispatch) {
                    $payload['s'] = $SequenceNumber
                    $payload['t'] = $EventName
                }

                ConvertTo-Json -InputObject $payload -Compress
            }

            function Send-Heartbeat {
                $heartbeat = New-DiscordPayload -Opcode 'Heartbeat' -Data $heartbeatSequence
                [ArraySegment[byte]]$bytes = [Text.Encoding]::UTF8.GetBytes($heartbeat)
                Write-Debug "Sending heartbeat: [$heartbeatSequence]"
                $sendResult = $WebSocket.SendAsync($bytes, [Net.WebSockets.WebSocketMessageType]::Text, $true, $ct).GetAwaiter().GetResult()
                $script:heartbeatSequence += 1
                $stopWatch.Restart()
            }

            function Send-Indentify {
                $data = [pscustomobject]@{
                    token = $Token
                    properties = @{
                        '$os'      = 'PowerShell'
                        '$browser' = 'PoshBot'
                        '$device'  = 'PoshBot'
                    }
                    compress = $false
                }
                $id = New-DiscordPayload -Opcode 'Identify' -Data $data
                [ArraySegment[byte]]$bytes = [Text.Encoding]::UTF8.GetBytes($id)
                Write-Debug 'Sending Identify packet'
                $sendResult = $WebSocket.SendAsync($bytes, [Net.WebSockets.WebSocketMessageType]::Text, $true, $ct).GetAwaiter().GetResult()
            }

            # Maintain websocket connection and put received messages on the output stream
            function Recv-Msg {
                $jsonResult = ""
                do {
                    $taskResult = $webSocket.ReceiveAsync($buffer, $ct)
                    while (-not $taskResult.IsCompleted) {
                        if ($stopWatch.ElapsedMilliseconds -ge $heartbeatInterval) {
                            Send-Heartbeat
                        }
                        [Threading.Thread]::Sleep(10)
                    }
                    $jsonResult += [Text.Encoding]::UTF8.GetString($buffer, 0, $taskResult.Result.Count)
                } until (
                    $taskResult.Result.EndOfMessage
                )

                if (-not [string]::IsNullOrEmpty($jsonResult)) {
                    Write-Debug "Recv-Msg: $jsonResult"
                    $jsonParams = @{
                        InputObject = $jsonResult
                    }
                    if ($global:PSVersionTable.PSVersion.Major -ge 6) {
                        $jsonParams['Depth'] = 50
                    }
                    try {
                        $msgs = ConvertFrom-Json @jsonParams
                    }
                    catch {
                        throw $Error[0]
                    }
                    foreach ($msg in $msgs) {
                        switch ([DiscordOpCode]$msg.op) {
                            ([DiscordOpCode]::Dispatch) {
                                # Inspec message and determine if it's from the bot. If so, ignore it
                                if (-not ($msg.d.user_id -and $msg.d.user_id -eq $BotId) -and
                                    -not ($msg.d.author.id -and $msg.d.author.id -eq $BotId)) {
                                    # Pass along message
                                    ConvertTo-Json -InputObject $msg -Compress
                                }
                                break
                            }
                            ([DiscordOpCode]::Heartbeat) {
                                # TODO
                                # Not sure this is needed
                                break
                            }
                            ([DiscordOpCode]::Reconnect) {
                                # TODO
                                # Add reconnect logic
                                break
                            }
                            ([DiscordOpCode]::InvalidSession) {
                                # TODO
                                # Deal with invalid session
                                break
                            }
                            ([DiscordOpCode]::Hello) {
                                # Received heartbeat interval and server debug info
                                Write-Debug "Received heartbeat interval [$($msg.d.heartbeat_interval)]"
                                $script:heartbeatInterval = $msg.d.heartbeat_interval

                                # Send identity back only once
                                if ($firstHeartbeat) {
                                    Send-Indentify
                                    $firstHeartbeat = $false
                                }
                                break
                            }
                            ([DiscordOpCode]::HeartbeatAck) {
                                Write-Debug 'Received heartbeat ack'
                                break
                            }
                        }
                    }
                }
            }

            $stopWatch = [System.Diagnostics.Stopwatch]::new()
            $stopWatch.Start()
            $firstHeartbeat = $true
            while ($webSocket.State -eq [Net.WebSockets.WebSocketState]::Open) {
                Recv-Msg
            }

            $socketStatus = [pscustomobject]@{
                State       = $webSocket.State
                Status      = $webSocket.CloseStatus
                Description = $webSocket.CloseStatusDescription
            }
            $socketStatusStr = ($socketStatus | Format-List | Out-String).Trim()
            Write-Host "Websocket state is [$($webSocket.State)]"
            Write-Warning -Message "Websocket state is [$($webSocket.State.ToString())].`n$socketStatusStr"
        }

        try {
            $jobParams = @{
                Name         = 'ReceiveDiscordGatewayMessages'
                ScriptBlock  = $recv
                ArgumentList = @($this.GatewayUrl, $this.Config.Credential.GetNetworkCredential().password, $this.Config.Credential.Username)
                ErrorAction  = 'Stop'
                Verbose      = $true
            }
            $this.ReceiveJob = Start-Job @jobParams
            $this.Connected = $true
            $this.Status = [ConnectionStatus]::Connected
            $this.LogInfo("Started websocket receive job [$($this.ReceiveJob.Id)")
        } catch {
            $this.LogInfo([LogSeverity]::Error, "$($_.Exception.Message)", [ExceptionFormatter]::Summarize($_))
        }
    }

    # Read all available data from receive job
    [string[]]ReadReceiveJob() {
        # Read stream info from the job so we can log them
        $infoStream    = $this.ReceiveJob.ChildJobs[0].Information.ReadAll()
        $warningStream = $this.ReceiveJob.ChildJobs[0].Warning.ReadAll()
        $errStream     = $this.ReceiveJob.ChildJobs[0].Error.ReadAll()
        $verboseStream = $this.ReceiveJob.ChildJobs[0].Verbose.ReadAll()
        $debugStream   = $this.ReceiveJob.ChildJobs[0].Debug.ReadAll()
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
            <# if ($this.ReceiveJob.State -eq 'Failed') {
                $this.LogInfo([LogSeverity]::Warning, "Failure message: $($this.ReceiveJob | Receive-Job *>&1)")
            } #>
            Start-Sleep -Seconds 5
            $this.Connect()
        }

        # Return output stream
        if ($this.ReceiveJob.HasMoreData) {
            [string[]]$jobResult = $this.ReceiveJob.ChildJobs[0].Output.ReadAll()
            return $jobResult
        } else {
            return $null
        }
    }

    # Stop the receive job
    [void]Disconnect() {
        $this.LogInfo('Closing websocket')
        if ($this.ReceiveJob) {
            $this.LogInfo("Stopping receive job [$($this.ReceiveJob.Id)]")
            $this.ReceiveJob | Stop-Job -Confirm:$false -PassThru | Remove-Job -Force -ErrorAction SilentlyContinue
        }
        $this.Connected = $false
        $this.Status = [ConnectionStatus]::Disconnected
    }
}
