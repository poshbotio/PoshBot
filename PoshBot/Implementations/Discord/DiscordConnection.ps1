class DiscordConnection : Connection {
  [System.Net.WebSockets.ClientWebSocket]$WebSocket
  [pscustomobject]$LoginData
  [string]$UserName
  [string]$Domain
  [string]$WebSocketUrl
  [bool]$Connected
  [object]$ReceiveJob = $null

  DiscordConnection() {
    $this.$WebSocket = New-Object System.Net.WebSockets.ClientWebSocket
    $this.$WebSocket.Options.KeepAliveInterval = 5
  }

  # Connect to Discord and start receiving messages
  [void]Connect() {
    If ($null -eq $this.$ReceiveJob -or $this.$ReceiveJob.State -ne 'Running') {
      $this.LogDebug('Connecting to Discord Gateway')
      $this.GatewayConnect()
      $this.StartReceiveJob()
    } Else {
      $this.LogDebug([LogSeverity]::Warning, 'Receive job is already running')
    }
  }

  # Log into Discord with the bot token and get a URL to connect to via websockets
  [void]GatewayConnect() {
    $Token = $this.Config.Credential.GetNetworkCredential().Password
    $Url   = "https://discordapp.com/api/gateway"
    $Headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $Headers.Add('Authorization', "Bot $Token")

    Try {
      $Response = Invoke-RestMethod -Uri $Url -Method Get -Headers $Headers -Verbose:$false -ErrorAction Stop
      $this.LoginData = $Response
      $this.LogInfo('Successfully authenticated to Discord Gateway')
      $this.WebSocketUrl = $Response.url
      $this.Shards       = $Response.shards
      $this.SessionStartLimit = $Response.session_start_limit
    } Catch {
      $this.LogInfo([LogSeverity]::Error, 'Error connecting to Discord Gateway', [ExceptionFormatter]::Summarize($_))
    }
  }

  [void]StartReceiveJob() {
    $Receive = {
      [cmdletbinding()]
      param (
        [parameter(mandatory)]
        $Url
      )

      # Connect to websocket
      Write-Verbose "[DiscordBackend:ReceiveJob] Connecting to websocket at [$($Url)]"
      [System.Net.WebSockets.ClientWebSocket]$WebSocket = New-Object System.Net.WebSockets.ClientWebSocket
      $CancellationTokenSource = New-Object System.Threading.CancellationTokenSource
      $Task = $WebSocket.ConnectAsync($url, $CancellationTokenSource.Token)
      Do { Start-Sleep -Milliseconds 100 }
      Until ($Task.IsCompleted)

      # Receive messages and put on output stream so the backend can read them
      [ArraySegment[byte]]$Buffer = [byte[]]::new(4096)
      $CancellationToken = New-Object System.Threading.CancellationToken
      $TaskResult = $null
      While ($WebSocket.State -eq [System.Net.WebSockets.WebSocketState]::Open) {
        Do {
          $TaskResult = $WebSocket.ReceiveAsync($Buffer, $CancellationToken)
          While (-not $TaskResult.IsCompleted) {
            Start-Sleep -Milliseconds 100
          }
        } Until ( $TaskResult.Result.Count -lt 4096)
        $JsonResult = [System.Text.Encoding]::UTF8.GetString($Buffer, 0, $TaskResult.Result.Count)

        If (-not [string]::IsNullOrEmpty($JsonResult)) { $JsonResult }
      }
      $SocketStatus = [pscustomobject]@{
        State                  = $WebSocket.State
        CloseStatus            = $WebSocket.CloseStatus
        CloseStatusDescription = $WebSocket.CloseStatusDescription
      }
      $SocketStatusString = ($SocketStatus | Format-List | Out-String).Trim()
      Write-Warning -Message "Websocket state is [$($Websocket.State.ToString())].`n$socketStatusStr"
    }

    Try {
      $JobParameters = @{
        Name = 'ReceiveGatewayMessages'
        ScriptBlock = $Receive
        ArgumentList = $this.WebSocketUrl
        ErrorAction = Stop
        Verbose = $true
      }
      $this.ReceiveJob = Start-Job @JobParameters
      $this.Connected = $true
      $this.Status = [ConnectionStatus]::Connected
      $this.LogInfo
    } Catch {
      $this.LogInfo([LogSeverity]::Error, "$($_.Exception.Message)", [ExceptionFormatter]::Summarize($_))
    }
  }

  # Read all available data from the job
  [string]ReadReceiveJob() {
    # Read stream info from the job so we can log them
    $InformationStream = $this.ReceiveJob.ChildJobs[0].Information.ReadAll()
    $WarningStream     = $this.ReceiveJob.ChildJobs[0].Warning.ReadAll()
    $ErrorStream       = $this.ReceiveJob.ChildJobs[0].Error.ReadAll()
    $VerboseStream     = $this.ReceiveJob.ChildJobs[0].Verbose.ReadAll()
    $DebugStream       = $this.ReceiveJob.ChildJobs[0].Debug.ReadAll()
    ForEach ($Item in $InformationStream) { $this.LogInfo($Item.ToString())}
    ForEach ($Item in $WarningStream)     { $this.LogInfo([LogSeverity]::Warning, $Item.ToString())}
    ForEach ($Item in $ErrorStream)       { $this.LogInfo([LogSeverity]::Error, $Item.ToString())}
    ForEach ($Item in $VerboseStream)     { $this.LogInfo($Item.ToString())}
    ForEach ($Item in $DebugStream)       { $this.LogInfo($Item.ToString())}

    # The receive job stopped for some resaon. Reestablish the connection if the job isn't running
    If ($this.ReceiveJob.State -ne 'Running') {
      $this.LogInfo([LogSeverity]::Warning, "Receive job is [$($this.ReceiveJob.Stat)]. Attempting to reconnect...")
      Start-Sleep -Seconds 5
      $this.Connect()
    }

    If ($this.ReceiveJob.HasMoreData) {
      return $this.ReceiveJob.ChildJobs[0].Output.ReadAll()
    } else {
      return $null
    }
  }

  # Stop the receive job
  [void]Disconnect() {
    $this.LogInfo('Closing websocket')
    If ($this.ReceiveJob) {
      $this.LogInfo("Stopping receive job [$($this.ReceiveJob.Id)]")
    }
    
  }
}