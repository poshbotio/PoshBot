
# The PoshBot configuration
# This will hold what backend implmentatino of the bot is being run (Slack, HipChat, etc)
# This will be populated via Get-PoshBotConfig

class Config {
    
    [string]$Backend

    # Default storage module to use
    [string]$StorageModule = 'disk'

    # Default data directory used by 'disk' storage module
    [string]$DataDir = "$env:temp/PoshBot/Data"

    # Default log directory
    [string]$LogDir = "$env:temp/PoshBot/Logs"

    # The default location to download plugins (PowerShell modules) from
    [string]$PluginRepository = 'PSGallery'

    [hashtable]$Identity = {
        UserName = 'poshbot'
        Password = 'hunter2'
    }

    [string]$CommandPrefix = '!'

    # Alternate names the bot will respond with besides the prefix above.
    # Example:
    # !make me a sandwhich
    # > PoshBot make me a sandwhich
    [string[]]$AlternateCommandPrefixes

    # You may want to insert seperatrs between the prefix and the command itself.
    # ':', ',', ';'
    [string[]]$AlernatePrefixSeperators

    [bool]$MuteRestrictedCommandMessage = $false

    [bool]$MuteCommandNotFoundMessage = $false

    [int]$MaxMessageSize = 10000

    static [Config]$instance

    static [Config]GetInstance() {
        if ([Config]::instance -eq $null) {
            [Config]::instance = [Config]::new()
        }
        return [Config]::instance
    }
}