
# .Net Core implementation of Service Bus receiver
$platform = 'linux'
Add-Type -Path "$ModulePath/lib/$platform/Microsoft.Azure.Amqp.dll"
Add-Type -Path "$ModulePath/lib/$platform/Microsoft.Azure.ServiceBus.dll"

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
            $ReceiverMessages.Enqueue($payload)
        }
    }
}
$receiver.CloseAsync().GetAwaiter().GetResult()
