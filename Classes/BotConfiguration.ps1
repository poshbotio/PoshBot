
class BotConfiguration {

    [string]$LogDirectory = (Join-Path -Path $env:USERPROFILE -ChildPath '.poshbot')

    [string]$PluginDirectory = (Join-Path -Path $env:USERPROFILE -ChildPath '.poshbot')

    [string[]]$PluginRepository = @('PSGallery')

    [string[]]$ModuleManifestsToLoad = @()

    [LogLevel]$LogLevel = [LogLevel]::Verbose

    [hashtable]$BackendConfiguration = @{
        Type = 'Slack'
    }

    [string[]]$BotAdmins = @()

    [char]$CommandPrefix = '!'

    [string[]]$AlternateCommandPrefixes = @('poshbot')

    [char[]]$AlternateCommandPrefixSeperators = @(':', ',', ';')

    [string[]]$SendCommandResponseToPrivate = @()

    [bool]$MuteUnknownCommand = $false
}