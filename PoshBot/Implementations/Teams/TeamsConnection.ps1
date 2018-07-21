


class TeamsConnection : Connection {

    [object]$ReceiveJob = $null

    hidden [pscustomobject]$_AccessTokenInfo

    [bool]$Connected

    TeamsConnection([TeamsConnectionConfig]$Config) {
        $this.Config = $Config
    }

    # Connect to Teams and start receiving messages
    [void]Connect() {
        if ($null -eq $this.ReceiveJob -or $this.ReceiveJob.State -ne 'Running') {
            $this.Authenticate()
            $this.StartReceiveJob()
        } else {
            $this.LogDebug([LogSeverity]::Warning, 'Receive job is already running')
        }
    }

    # Authenticate with Teams and get token
    [void]Authenticate() {
        try {
            $authUrl = 'https://login.microsoftonline.com/botframework.com/oauth2/v2.0/token'
            $payload = @{
                grant_type    = 'client_credentials'
                client_id     = $this.Config.Credential.Username
                client_secret = $this.Config.Credential.GetNetworkCredential().password
                scope         = 'https://api.botframework.com/.default'
            }
            $response = Invoke-RestMethod -Uri $authUrl -Method Post -Body $payload -Verbose:$false
            $this._AccessTokenInfo = $response
        } catch {
            $this.LogInfo([LogSeverity]::Error, 'Error authenticating to Teams', [ExceptionFormatter]::Summarize($_))
        }
    }

    [void]StartReceiveJob() {

        # Service Bus receive job
        $recv = {
            [cmdletbinding()]
            param(
                [parameter(Mandatory)]
                [string]$ModulePath,

                [parameter(Mandatory)]
                [string]$ServiceBusNamespace,

                [parameter(Mandatory)]
                [string]$QueueName,

                [parameter(Mandatory)]
                [string]$AccessKeyName,

                [parameter(Mandatory)]
                [string]$AccessKey
            )

            # Load Service Bus DLLs
            if (($null -eq $IsWindows) -or $IsWindows) {
                $platform = 'windows'
                [Void][System.Reflection.Assembly]::LoadFrom("$ModulePath/lib/$platform/netstandard.dll")
            } else {
                $platform = 'linux'
            }
            @(
                Resolve-Path -Path $ModulePath/lib/$platform/Microsoft.Azure.Amqp.dll
                Resolve-Path -Path $ModulePath/lib/$platform/Microsoft.Azure.ServiceBus.dll
            ) | ForEach-Object {
                [Void][System.Reflection.Assembly]::LoadFrom($_)
            }

            # Create receiver
            $connectionString = "Endpoint=sb://{0}.servicebus.windows.net/;SharedAccessKeyName={1};SharedAccessKey={2}" -f $ServiceBusNamespace, $AccessKeyName, $AccessKey
            $receiver = [Microsoft.Azure.ServiceBus.Core.MessageReceiver]::new(
                $connectionString,
                $QueueName,
                [Microsoft.Azure.ServiceBus.ReceiveMode]::PeekLock,
                [Microsoft.Azure.ServiceBus.RetryPolicy]::Default,
                0
            )
            $receiver.OperationTimeout = [timespan]::new(0, 0, 0, 5)

            # Receive messages and put on output stream so the backend can read them
            while (-not $receiver.IsClosedOrClosing) {
                $msg = $receiver.ReceiveAsync().GetAwaiter().GetResult()
                if ($msg) {
                    $receiver.CompleteAsync($msg.SystemProperties.LockToken) > $null
                    $payload = [System.Text.Encoding]::UTF8.GetString($msg.Body)
                    if (-not [string]::IsNullOrEmpty($payload)) {
                        $payload
                    }
                }
                Start-Sleep -Milliseconds 10
            }
            $receiver.CloseAsync()
        }

        try {
            $cred = [pscredential]::new($this.Config.AccessKeyName, $this.Config.AccessKey)
            $jobParams = @{
                Name         = 'TeamsServiceBusListener'
                ScriptBlock  = $recv
                ErrorAction  = 'Stop'
                Verbose      = $true
                ArgumentList = @(
                    $script:moduleBase
                    $this.Config.ServiceBusNamespace
                    $this.Config.QueueName
                    $this.Config.AccessKeyName
                    $cred.GetNetworkCredential().password
                )
            }
            $this.ReceiveJob = Start-Job @jobParams
            $this.Connected = $true
            $this.Status = [ConnectionStatus]::Connected
            $this.LogInfo("Started Teams Service Bus receive job [$($this.ReceiveJob.Id)]")
        } catch {
            $this.LogInfo([LogSeverity]::Error, "$($_.Exception.Message)", [ExceptionFormatter]::Summarize($_))
        }
    }

    [string]ReadReceiveJob() {
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
            Start-Sleep -Seconds 5
            $this.Connect()
        }

        if ($this.ReceiveJob.HasMoreData) {
            return $this.ReceiveJob.ChildJobs[0].Output.ReadAll()
        } else {
            return $null
        }
    }

    # Stop the Teams listener
    [void]Disconnect() {
        $this.LogInfo('Stopping Service Bus listener')
        if ($this.ReceiveJob) {
            $this.LogInfo("Stopping receive job [$($this.ReceiveJob.Id)]")
            $this.ReceiveJob | Stop-Job -Confirm:$false -PassThru | Remove-Job -Force -ErrorAction SilentlyContinue
        }
        $this.Connected = $false
        $this.Status = [ConnectionStatus]::Disconnected
    }
}
