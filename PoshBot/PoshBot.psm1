
$script:moduleRoot = $PSScriptRoot

$script:botTracker = @{

}

# Out custom attribute that external modules can decorate
# command with. This controls the command behavior when imported
Add-Type -TypeDefinition @"
namespace PoshBot {

    public enum TriggerType {
        Command,
        Event,
        Regex,
        Timer
    }

    public class BotCommand : System.Attribute {
        public string CommandName { get; set; }
        public bool HideFromHelp { get; set; }
        public string Regex { get; set; }
        public string MessageType { get; set; }
        public string MessageSubtype { get; set; }
        public string[] Permissions { get; set; }

        private TriggerType _triggerType = TriggerType.Command;
        private bool _command = true;
        private bool _keepHistory = true;

        public TriggerType TriggerType {
            get { return _triggerType; }
            set { _triggerType = value; }
        }

        public bool Command {
            get { return _command; }
            set { _command = value; }
        }

        public bool KeepHistory {
            get { return _keepHistory; }
            set { _keepHistory = value; }
        }
    }

    public class FromConfig : System.Attribute {
        public string Name { get; set; }

        public FromConfig() {}

        public FromConfig(string Name) {
            this.Name = Name;
        }
    }
}
"@

# Base classes and associated functions
@(
    'Logger'
    'ExceptionFormatter'
    'BotCommand'
    'Event'
    'Person'
    'Room'
    'Message'
    'Response'
    'Card'
    'CommandResult'
    'CommandParser'
    'Permission'
    'AccessFilter'
    'Role'
    'Group'
    'Trigger'
    'StorageProvider'
    'RoleManager'
    'Command'
    'CommandHistory'
    'Plugin'
    'PluginCommand'
    'CommandExecutor'
    'ConfigProvidedParameter'
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
    Event
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
    'Get-PoshBot'
    'Get-PoshBotConfiguration'
    'New-PoshBotAce'
    'New-PoshBotBackend'
    'New-PoshBotConfiguration'
    'New-PoshBotInstance'
    'New-PoshBotScheduledTask'
    'New-PoshBotSlackBackend'
    'New-HelloPlugin'
    'New-PoshBotCardResponse'
    'New-PoshBotTextResponse'
    'Save-PoshBotConfiguration'
    'Start-PoshBot'
    'Stop-Poshbot'
)
