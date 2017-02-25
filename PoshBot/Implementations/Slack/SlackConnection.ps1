class SlackConnection : Connection {

    [System.Net.WebSockets.ClientWebSocket]$WebSocket
    #[System.Threading.CancellationTokenSource]$CTS
    [pscustomobject]$LoginData
    [string]$UserName
    [string]$Domain

    [string]$WebSocketUrl

    [bool]$Connected

    SlackConnection() {
        $this.WebSocket = New-Object System.Net.WebSockets.ClientWebSocket
        $this.WebSocket.Options.KeepAliveInterval = 5
    }

    [void]Connect() {
        if ($this.WebSocket.State -ne [System.Net.WebSockets.WebSocketState]::Open) {
            $this.RtmConnect()
            $this.ConnectWebSocket()
        }
    }

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

    [void]ConnectWebSocket() {
        Write-Verbose "[SlackConnection:ConnectWebSocket] Connecting to websocket at [$($this.WebSocketUrl)]"
        #$this.WebSocket = New-Object System.Net.WebSockets.ClientWebSocket
        #$this.WebSocket.Options.KeepAliveInterval = 5

        #$r = $this.WebSocket.ConnectAsync($this.WebSocketUrl, $this.CTS.Token).GetAwaiter().GetResult()
        # Connect to websocket
        $cts = New-Object System.Threading.CancellationTokenSource
        $task = $this.WebSocket.ConnectAsync($this.WebSocketUrl, $cts.Token)
        do { Start-Sleep -Milliseconds 100 }
        until ($task.IsCompleted)

        $this.Connected = $true
        $this.Status = [ConnectionStatus]::Connected
    }

    [void]Disconnect([System.Net.WebSockets.WebSocketCloseStatus]$Reason = [System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure) {
        Write-Verbose -Message '[SlackConnection:Disconnect] Closing websocket'
        #$cs = [System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure
        $cts = New-Object System.Threading.CancellationTokenSource
        $this.WebSocket.CloseAsync($Reason, 'Closing connection', $cts.Token)
        $this.Connected = $false
        $this.Status = [ConnectionStatus]::Disconnected
    }
}
