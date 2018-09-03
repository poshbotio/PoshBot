
class TeamsConnection : Connection {

    [object]$ReceiveJob = $null

    [System.Management.Automation.PowerShell]$PowerShell

    # To control the background thread
    [System.Collections.Concurrent.ConcurrentDictionary[string,psobject]]$ReceiverControl = [System.Collections.Concurrent.ConcurrentDictionary[string,psobject]]@{}

    # Shared queue between the class and the background thread to receive messages with
    [System.Collections.Concurrent.ConcurrentQueue[string]]$ReceiverMessages = [System.Collections.Concurrent.ConcurrentQueue[string]]@{}

    [object]$Handler = $null

    hidden [pscustomobject]$_AccessTokenInfo

    hidden [datetime]$_AccessTokenExpiration

    [bool]$Connected

    TeamsConnection([TeamsConnectionConfig]$Config) {
        $this.Config = $Config
    }

    # Setup runspace for the receiver thread to run in
    [void]Initialize() {
        $runspacePool = [RunspaceFactory]::CreateRunspacePool(1, 1)
        $runspacePool.Open()
        $this.PowerShell = [PowerShell]::Create()
        $this.PowerShell.RunspacePool = $runspacePool
        $this.ReceiverControl['ShouldRun'] = $true
    }

    # Connect to Teams and start receiving messages
    [void]Connect() {
        #if ($null -eq $this.ReceiveJob -or $this.ReceiveJob.State -ne 'Running') {
        if ($this.PowerShell.InvocationStateInfo.State -ne 'Running') {
            $this.Initialize()
            $this.Authenticate()
            $this.StartReceiveThread()
        } else {
            $this.LogDebug([LogSeverity]::Warning, 'Receive thread is already running')
        }
    }

    # Authenticate with Teams and get token
    [void]Authenticate() {
        try {
            $this.LogDebug('Getting Bot Framework access token')
            $authUrl = 'https://login.microsoftonline.com/botframework.com/oauth2/v2.0/token'
            $payload = @{
                grant_type    = 'client_credentials'
                client_id     = $this.Config.Credential.Username
                client_secret = $this.Config.Credential.GetNetworkCredential().password
                scope         = 'https://api.botframework.com/.default'
            }
            $response = Invoke-RestMethod -Uri $authUrl -Method Post -Body $payload -Verbose:$false
            $this._AccessTokenExpiration = ([datetime]::Now).AddSeconds($response.expires_in)
            $this._AccessTokenInfo = $response
        } catch {
            $this.LogInfo([LogSeverity]::Error, 'Error authenticating to Teams', [ExceptionFormatter]::Summarize($_))
            throw $_
        }
    }

    [void]StartReceiveThread() {

        # Service Bus receive script
        $recv = {
            [cmdletbinding()]
            param(
                [parameter(Mandatory)]
                [System.Collections.Concurrent.ConcurrentDictionary[string,psobject]]$ReceiverControl,

                [parameter(Mandatory)]
                [System.Collections.Concurrent.ConcurrentQueue[string]]$ReceiverMessages,

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

            $connectionString = "Endpoint=sb://{0}.servicebus.windows.net/;SharedAccessKeyName={1};SharedAccessKey={2}" -f $ServiceBusNamespace, $AccessKeyName, $AccessKey
            $receiveTimeout = [timespan]::new(0, 0, 0, 5)

            # Honestly this is a pretty hacky way to go about using these
            # Service Bus DLLs but we can only implement one method or the
            # other without PSScriptAnalyzer freaking out about missing classes
            if ($PSVersionTable.PSEdition -eq 'Desktop') {
                . "$ModulePath/lib/windows/ServiceBusReceiver_net45.ps1"
            } else {
                . "$ModulePath/lib/linux/ServiceBusReceiver_netstandard.ps1"
            }
        }

        try {
            $cred = [pscredential]::new($this.Config.AccessKeyName, $this.Config.AccessKey)
            $runspaceParams = @{
                ReceiverControl     = $this.ReceiverControl
                ReceiverMessages    = $this.ReceiverMessages
                ModulePath          = $script:moduleBase
                ServiceBusNamespace = $this.Config.ServiceBusNamespace
                QueueName           = $this.Config.QueueName
                AccessKeyName       = $this.Config.AccessKeyName
                AccessKey           = $cred.GetNetworkCredential().password
            }

            $this.PowerShell.AddScript($recv)
            $this.PowerShell.AddParameters($runspaceParams) > $null
            $this.Handler = $this.PowerShell.BeginInvoke()
            $this.Connected = $true
            $this.Status = [ConnectionStatus]::Connected
            $this.LogInfo('Started Teams Service Bus background thread')
        } catch {
            $this.LogInfo([LogSeverity]::Error, "$($_.Exception.Message)", [ExceptionFormatter]::Summarize($_))
            $this.PowerShell.EndInvoke($this.Handler)
            $this.PowerShell.Dispose()
            $this.Connected = $false
            $this.Status = [ConnectionStatus]::Disconnected
        }
    }

    [string[]]ReadReceiveThread() {
        # # Read stream info from the job so we can log them
        # $infoStream    = $this.ReceiveJob.ChildJobs[0].Information.ReadAll()
        # $warningStream = $this.ReceiveJob.ChildJobs[0].Warning.ReadAll()
        # $errStream     = $this.ReceiveJob.ChildJobs[0].Error.ReadAll()
        # $verboseStream = $this.ReceiveJob.ChildJobs[0].Verbose.ReadAll()
        # $debugStream   = $this.ReceiveJob.ChildJobs[0].Debug.ReadAll()

        # foreach ($item in $infoStream) {
        #     $this.LogInfo($item.ToString())
        # }
        # foreach ($item in $warningStream) {
        #     $this.LogInfo([LogSeverity]::Warning, $item.ToString())
        # }
        # foreach ($item in $errStream) {
        #     $this.LogInfo([LogSeverity]::Error, $item.ToString())
        # }
        # foreach ($item in $verboseStream) {
        #     $this.LogVerbose($item.ToString())
        # }
        # foreach ($item in $debugStream) {
        #     $this.LogVerbose($item.ToString())
        # }

        # TODO
        # Read all the streams from the thread

        # Validate access token is still current and refresh
        # if expiration is less than half the token lifetime
        if (($this._AccessTokenExpiration - [datetime]::Now).TotalSeconds -lt 1800) {
            $this.LogDebug('Teams access token is expiring soon. Refreshing...')
            $this.Authenticate()
        }

        # The receive thread stopped for some reason. Reestablish the connection if it isn't running
        if ($this.PowerShell.InvocationStateInfo.State -ne 'Running') {

            # Log any errors from the background thread
            if ($this.PowerShell.Streams.Error.Count -gt 0) {
                $this.PowerShell.Streams.Error.Foreach({
                    $this.LogInfo([LogSeverity]::Error, "$($_.Exception.Message)", [ExceptionFormatter]::Summarize($_))
                })
            }
            $this.PowerShell.Streams.ClearStreams()

            $this.LogInfo([LogSeverity]::Warning, "Receive thread is [$($this.PowerShell.InvocationStateInfo.State)]. Attempting to reconnect...")
            Start-Sleep -Seconds 5
            $this.Connect()
        }

        # Dequeue messages from receiver thread
        if ($this.ReceiverMessages.Count -gt 0) {
            $dequeuedMessages = $null
            $messages = [System.Collections.Generic.LinkedList[string]]::new()
            while($this.ReceiverMessages.TryDequeue([ref]$dequeuedMessages)) {
                foreach ($m in $dequeuedMessages) {
                    $messages.Add($m) > $null
                }
            }
            return $messages
        } else {
            return $null
        }
    }

    # Stop the Teams listener
    [void]Disconnect() {
        $this.LogInfo('Stopping Service Bus receiver')
        $this.ReceiverControl.ShouldRun = $false
        $result = $this.PowerShell.EndInvoke($this.Handler)
        $this.PowerShell.Dispose()
        $this.Connected = $false
        $this.Status = [ConnectionStatus]::Disconnected
    }
}
