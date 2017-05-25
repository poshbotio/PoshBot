class SlackConnection : Connection {

    [System.Net.WebSockets.ClientWebSocket]$WebSocket
    [pscustomobject]$LoginData
    [string]$UserName
    [string]$Domain
    [string]$WebSocketUrl
    [bool]$Connected
    [object]$ReceiveJob = $null

    SlackConnection() {
        $this.WebSocket = New-Object System.Net.WebSockets.ClientWebSocket
        $this.WebSocket.Options.KeepAliveInterval = 5
    }

    # Connect to Slack and start receiving messages
    [void]Connect() {
        if ($null -eq $this.ReceiveJob -or $this.ReceiveJob.State -ne 'Running') {
            $this.RtmConnect()
            $this.StartReceiveJob()
        }
    }

    # Log in to Slack with the bot token and get a URL to connect to via websockets
    [void]RtmConnect() {
        $token = $this.Config.Credential.GetNetworkCredential().Password
        $url = "https://slack.com/api/rtm.start?token=$($token)&pretty=1"
        try {
            $r = Invoke-RestMethod -Uri $url -Method Get -Verbose:$false
            $this.LoginData = $r
            if ($r.ok) {
                Write-Verbose -Message "[SlackConnection:RtmConnect] Successfully authenticated to Slack at [$($r.Url)]"
                $this.WebSocketUrl = $r.url
                $this.Domain = $r.team.domain
                $this.UserName = $r.self.name
            } else {
                Write-Error '[SlackConnection:RtmConnect] Slack login error'
            }
        } catch {
            throw $_
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

            # Connect to websocket
            Write-Verbose "[SlackBackend:ReceiveJob] Connecting to websocket at [$($url)]"
            [System.Net.WebSockets.ClientWebSocket]$webSocket = New-Object System.Net.WebSockets.ClientWebSocket
            $cts = New-Object System.Threading.CancellationTokenSource
            $task = $webSocket.ConnectAsync($url, $cts.Token)
            do { Start-Sleep -Milliseconds 100 }
            until ($task.IsCompleted)

            # Receive messages and put on output stream so the backend can read them
            $buffer = (New-Object System.Byte[] 4096)
            $ct = New-Object System.Threading.CancellationToken
            $taskResult = $null
            while ($webSocket.State -eq [System.Net.WebSockets.WebSocketState]::Open) {
                do {
                    $taskResult = $webSocket.ReceiveAsync($buffer, $ct)
                    while (-not $taskResult.IsCompleted) {
                        Start-Sleep -Milliseconds 100
                    }
                } until (
                    $taskResult.Result.Count -lt 4096
                )
                $jsonResult = [System.Text.Encoding]::UTF8.GetString($buffer, 0, $taskResult.Result.Count)

                if (-not [string]::IsNullOrEmpty($jsonResult)) {
                    $jsonResult
                }
            }
        }
        try {
            $this.ReceiveJob = Start-Job -Name ReceiveRtmMessages -ScriptBlock $recv -ArgumentList $this.WebSocketUrl -ErrorAction Stop -Verbose
            $this.Connected = $true
            $this.Status = [ConnectionStatus]::Connected
            Write-Verbose "[SlackConnection:StartReceiveJob] Started websocket receive job [$($this.ReceiveJob.Id)]"
        } catch {
            throw $_
        }
    }

    # Read all available data from the job
    [string]ReadReceiveJob() {
        if ($this.ReceiveJob.HasMoreData) {
            return $this.ReceiveJob.ChildJobs[0].Output.ReadAll()
        } else {
            return $null
        }
    }

    # Stop the receive job
    [void]Disconnect([System.Net.WebSockets.WebSocketCloseStatus]$Reason = [System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure) {
        Write-Verbose -Message '[SlackConnection:Disconnect] Closing websocket'
        $this.ReceiveJob | Stop-Job -Confirm:$false
        $this.Connected = $false
        $this.Status = [ConnectionStatus]::Disconnected
    }
}
