
class BotConfiguration {

    [string]$Name = 'PoshBot'

    [string]$ConfigurationDirectory = (Join-Path -Path $env:USERPROFILE -ChildPath '.poshbot')

    [string]$LogDirectory = (Join-Path -Path $env:USERPROFILE -ChildPath '.poshbot')

    [string]$PluginDirectory = (Join-Path -Path $env:USERPROFILE -ChildPath '.poshbot')

    [string[]]$PluginRepository = @('PSGallery')

    [string[]]$ModuleManifestsToLoad = @()

    [LogLevel]$LogLevel = [LogLevel]::Verbose

    [int]$MaxLogSizeMB = 10

    [int]$MaxLogsToKeep = 5

    [bool]$LogCommandHistory = $true

    [int]$CommandHistoryMaxLogSizeMB = 10

    [int]$CommandHistoryMaxLogsToKeep = 5

    [hashtable]$BackendConfiguration = @{}

    [hashtable]$PluginConfiguration = @{}

    [string[]]$BotAdmins = @()

    [char]$CommandPrefix = '!'

    [string[]]$AlternateCommandPrefixes = @('poshbot')

    [char[]]$AlternateCommandPrefixSeperators = @(':', ',', ';')

    [string[]]$SendCommandResponseToPrivate = @()

    [bool]$MuteUnknownCommand = $false

    [bool]$AddCommandReactions = $true

    [ApprovalConfiguration]$ApprovalConfiguration = [ApprovalConfiguration]::new()
}
