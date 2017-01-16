
function New-PoshBotConfiguration {
    [cmdletbinding()]
    param(
        [string]$LogDirectory = (Join-Path -Path $env:USERPROFILE -ChildPath '.poshbot'),
        [string]$PluginDirectory = (Join-Path -Path $env:USERPROFILE -ChildPath '.poshbot'),
        [string[]]$PluginRepository = @('PSGallery'),
        [string[]]$ModuleManifestsToLoad = @(),
        [LogLevel]$LogLevel = [LogLevel]::Verbose,
        [string[]]$BotAdmins = @(),
        [char]$CommandPrefix = '!',
        [string[]]$AlternateCommandPrefixes = @('poshbot'),
        [char[]]$AlternateCommandPrefixSeperators = @(':', ',', ';'),
        [string[]]$SendCommandResponseToPrivate = @(),
        [bool]$MuteUnknownCommand = $false
    )

    $config = [BotConfiguration]::new()
    $config.AlternateCommandPrefixes = $AlternateCommandPrefixes
    $config.AlternateCommandPrefixSeperators = $AlternateCommandPrefixSeperators
    $config.BotAdmins = $BotAdmins
    $config.CommandPrefix = $CommandPrefix
    $config.LogDirectory = $LogDirectory
    $config.LogLevel = $LogLevel
    $config.ModuleManifestsToLoad = $ModuleManifestsToLoad
    $config.MuteUnknownCommand = $MuteUnknownCommand
    $config.PluginDirectory = $PluginDirectory
    $config.PluginRepository = $PluginRepository
    $config.SendCommandResponseToPrivate = $SendCommandResponseToPrivate

    $config
}
