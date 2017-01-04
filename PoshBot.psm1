
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
    'AccessControlEntry'
    'AccessFilter'
    'Role'
    'Trigger'
    'Command'
    'CommandHistory'
    'Plugin'
    'ConnectionConfig'
    'Connection'
    'Backend'
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

enum LogType {
    Debug
    System
    Audit
    Command
    Receive
}

enum TriggerType {
    Command
    Regex
    Timer
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
    'New-PoshBotAce'
    'New-PoshBotBackend'
    'New-PoshBotCommand'
    'New-PoshBotCommandDescription'
    'New-PoshBotInstance'
    'New-PoshBotPlugin'
    'New-PoshBotRole'
    'New-PoshBotSlackBackend'
    'New-PoshBotTrigger'
    'New-HelloPlugin'
)
