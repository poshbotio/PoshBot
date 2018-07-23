
class TeamsConnectionConfig : ConnectionConfig {
    [string]$BotName
    [string]$TeamId
    [string]$ServiceBusNamespace
    [string]$QueueName
    [string]$AccessKeyName
    [securestring]$AccessKey
}
