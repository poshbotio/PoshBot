
$script:moduleRoot = $PSScriptRoot

# Base classes and associated functions
@(
    'Logger'
    'ExceptionFormatter'
    #'Identifier'
    'BotCommand'
    'Event'
    'Person'
    'Room'
    'Message'
    'Response'
    'Card'
    'CommandResult'
    'CommandParser'
    'AccessFilter'
    'Role'
    'Trigger'
    'StorageProvider'
    'RoleManager'
    'Command'
    'CommandHistory'
    'CommandExecutor'
    'Plugin'
    'PluginCommand'
    'PluginManager'
    'ConnectionConfig'
    'Connection'
    'Backend'
    'BotConfiguration'
    'Bot'
) | ForEach-Object {
    . "$PSScriptRoot/Classes/$_.ps1"
}

# Some enums
enum AccessRight {
    Allow
    Deny
}

enum ConnectionStatus {
    Connected
    Disconnected
}

enum TriggerType {
    Command
    Regex
    Timer
}

enum LogLevel {
    Info = 1
    Verbose = 2
    Debug = 4
}

# Slack classes and associated functions
@(
    'SlackMessage'
    'SlackPerson'
    'SlackChannel'
    'SlackConnection'
    'SlackBackend'
) | ForEach-Object {
    . "$PSScriptRoot/Implementations/Slack/$_.ps1"
}

# Public functions
@( Get-ChildItem -Path "$PSScriptRoot/Public/*.ps1" -ErrorAction SilentlyContinue ) | ForEach-Object {
    . $_.FullName
}

# Private functions
@( Get-ChildItem -Path "$PSScriptRoot/Private/*.ps1" -ErrorAction SilentlyContinue ) | ForEach-Object {
    . $_.FullName
}

Export-ModuleMember -Function @(
    'Add-PoshBotPlugin'
    'Add-PoshBotPluginCommand'
    'Get-PoshBotConfiguration'
    'New-PoshBotAce'
    'New-PoshBotBackend'
    'New-PoshBotCommand'
    'New-PoshBotCommandDescription'
    'New-PoshBotConfiguration'
    'New-PoshBotInstance'
    'New-PoshBotPlugin'
    'New-PoshBotRole'
    'New-PoshBotSlackBackend'
    'New-PoshBotTrigger'
    'New-HelloPlugin'
    'New-PoshBotCardResponse'
    'New-PoshBotTextResponse'
    'Save-PoshBotConfiguration'
)
