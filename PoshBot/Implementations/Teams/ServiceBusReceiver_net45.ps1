
# Full .Net implementation of Service Bus receiver

$platform = 'windows'
#Add-Type -Path "$ModulePath/lib/$platform/Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
Add-Type -Path "$ModulePath/lib/$platform/Microsoft.ServiceBus.dll"


$factory      = [Microsoft.ServiceBus.Messaging.MessagingFactory]::CreateFromConnectionString($connectionString)
$receiver     = $factory.CreateMessageReceiver($QueueName, [Microsoft.ServiceBus.Messaging.ReceiveMode]::PeekLock)
$bindingFlags = [Reflection.BindingFlags] 'Public,Instance'

# Receive messages and add to shared queue so the backend can read them
while (-not $receiver.IsClosed -and $ReceiverControl.ShouldRun) {
    $msg = $receiver.ReceiveAsync($receiveTimeout).GetAwaiter().GetResult()
    if ($msg) {
        $receiver.CompleteAsync($msg.LockToken).GetAwaiter().GetResult() > $null

        # https://social.msdn.microsoft.com/Forums/en-US/6800cf74-9497-4a85-b059-a22d5dc28227/how-to-call-azure-service-bus-generic-method-in-powershell-brokeredmessagegetbody?forum=servbus
        $stream = $msg.GetType().GetMethod('GetBody', $bindingFlags, $null, @(), $null).MakeGenericMethod([System.IO.Stream]).Invoke($msg, $null)
        $streamReader = [System.IO.StreamReader]::new($stream)
        $payload = $streamReader.ReadToEnd()
        $streamReader.Dispose()
        $stream.Dispose()
        if (-not [string]::IsNullOrEmpty($payload)) {
            $ReceiverMessages.Enqueue($payload) > $null
        }
    }
}
$receiver.Close()
