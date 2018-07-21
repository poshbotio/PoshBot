
class TeamsConnectionConfig : ConnectionConfig {
    [string]$ServiceBusNamespace
    [string]$QueueName
    [string]$AccessKeyName
    [securestring]$AccessKey
}
