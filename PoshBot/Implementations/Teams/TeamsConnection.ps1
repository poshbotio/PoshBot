


class TeamsConnection : Connection {

    [object]$ReceiveJob = $null

    [System.Management.Automation.PowerShell]$PowerShell

    # To control the background thread
    [System.Collections.Concurrent.ConcurrentDictionary[string,psobject]]$ReceiverControl = [System.Collections.Concurrent.ConcurrentDictionary[string,psobject]]@{}

    # Shared queue between the class and the background thread to receive messages with
    [System.Collections.Concurrent.ConcurrentQueue[string]]$ReceiverMessages = [System.Collections.Concurrent.ConcurrentQueue[string]]@{}

    [object]$Handler = $null

    hidden [pscustomobject]$_AccessTokenInfo

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

            # Load Service Bus DLLs
            try {
                if ($PSVersionTable.PSEdition -eq 'Desktop') {
                    $platform = 'windows'
                    # [System.Reflection.Assembly]::LoadFrom((Resolve-Path "$ModulePath/lib/$platform/Microsoft.IdentityModel.Clients.ActiveDirectory.dll")) > $null
                    # [System.Reflection.Assembly]::LoadFrom((Resolve-Path "$ModulePath/lib/$platform/Microsoft.ServiceBus.dll")) > $null
                    Add-Type -Path "$ModulePath/lib/$platform/netstandard.dll"
                    Add-Type -Path "$ModulePath/lib/$platform/System.Diagnostics.DiagnosticSource.dll"
                    Add-Type -Path "$ModulePath/lib/$platform/Microsoft.Azure.Amqp.dll"
                    Add-Type -Path "$ModulePath/lib/$platform/Microsoft.Azure.ServiceBus.dll"
                } else {
                    $platform = 'linux'
                    Add-Type -Path "$ModulePath/lib/$platform/Microsoft.Azure.Amqp.dll"
                    Add-Type -Path "$ModulePath/lib/$platform/Microsoft.Azure.ServiceBus.dll"
                }
            } catch {
                throw $_
            }

            $connectionString = "Endpoint=sb://{0}.servicebus.windows.net/;SharedAccessKeyName={1};SharedAccessKey={2}" -f $ServiceBusNamespace, $AccessKeyName, $AccessKey
            $receiveTimeout = [timespan]::new(0, 0, 0, 5)

            # Create Service Bus receiver
            # Full .Net uses a different SDK therefore the implemented differs a bit from the .Net core version
            # if ($PSVersionTable.PSEdition -eq 'Desktop') {

            #     $factory = [Microsoft.ServiceBus.Messaging.MessagingFactory]::CreateFromConnectionString($connectionString)
            #     $receiver = $factory.CreateMessageReceiver($QueueName, [Microsoft.ServiceBus.Messaging.ReceiveMode]::PeekLock)
            #     $bindingFlags = [Reflection.BindingFlags] 'Public,Instance'

            #     # Receive messages and add to shared queue so the backend can read them
            #     while (-not $receiver.IsClosed -and $ReceiverControl.ShouldRun) {
            #         $msg = $receiver.ReceiveAsync($receiveTimeout).GetAwaiter().GetResult()
            #         if ($msg) {
            #             $receiver.CompleteAsync($msg.LockToken).GetAwaiter().GetResult() > $null

            #             # https://social.msdn.microsoft.com/Forums/en-US/6800cf74-9497-4a85-b059-a22d5dc28227/how-to-call-azure-service-bus-generic-method-in-powershell-brokeredmessagegetbody?forum=servbus
            #             $stream = $msg.GetType().GetMethod('GetBody', $bindingFlags, $null, @(), $null).MakeGenericMethod([System.IO.Stream]).Invoke($msg, $null)
            #             $streamReader = [System.IO.StreamReader]::new($stream)
            #             $payload = $streamReader.ReadToEnd()
            #             $streamReader.Dispose()
            #             $stream.Dispose()
            #             if (-not [string]::IsNullOrEmpty($payload)) {
            #                 $ReceiverMessages.Enqueue($payload) > $null
            #             }
            #         }
            #     }
            #     $receiver.Close()
            # } else {

            $receiver = [Microsoft.Azure.ServiceBus.Core.MessageReceiver]::new(
                $connectionString,
                $QueueName,
                [Microsoft.Azure.ServiceBus.ReceiveMode]::PeekLock,
                [Microsoft.Azure.ServiceBus.RetryPolicy]::Default,
                0
            )
            $receiver.OperationTimeout = $receiveTimeout

            # Receive messages and add to shared queue so the backend can read them
            while (-not $receiver.IsClosedOrClosing -and $ReceiverControl.ShouldRun) {
                $msg = $receiver.ReceiveAsync().GetAwaiter().GetResult()
                if ($msg) {
                    $receiver.CompleteAsync($msg.SystemProperties.LockToken) > $null
                    $payload = [System.Text.Encoding]::UTF8.GetString($msg.Body)
                    if (-not [string]::IsNullOrEmpty($payload)) {
                        #$payload
                        $ReceiverMessages.Enqueue($payload)
                    }
                }
            }
            $receiver.CloseAsync().GetAwaiter().GetResult()
            # }
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

        # The receive thread stopped for some reason. Reestablish the connection if it isn't running
        if ($this.PowerShell.InvocationStateInfo.State -ne 'Running') {
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
