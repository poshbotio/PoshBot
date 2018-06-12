
class BotConfiguration {

    [string]$Name = 'PoshBot'

    [string]$ConfigurationDirectory = $script:defaultPoshBotDir

    [string]$LogDirectory = $script:defaultPoshBotDir

    [string]$PluginDirectory = $script:defaultPoshBotDir

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

    [bool]$DisallowDMs = $false

    [int]$FormatEnumerationLimitOverride = -1

    [ChannelRule[]]$ChannelRules = @([ChannelRule]::new())

    [ApprovalConfiguration]$ApprovalConfiguration = [ApprovalConfiguration]::new()

    [BotConfiguration] SerializeInstance([PSObject]$DeserializedObject) {
        return [BotConfiguration]::Serialize($DeserializedObject)
    }

    static [BotConfiguration] Serialize([PSObject]$DeserializedObject) {
        $bc = [BotConfiguration]::new()
        $bc.Name                             = $DeserializedObject.Name
        $bc.ConfigurationDirectory           = $DeserializedObject.ConfigurationDirectory
        $bc.LogDirectory                     = $DeserializedObject.LogDirectory
        $bc.PluginDirectory                  = $DeserializedObject.PluginDirectory
        $bc.PluginRepository                 = $DeserializedObject.PluginRepository
        $bc.ModuleManifestsToLoad            = $DeserializedObject.ModuleManifestsToLoad
        $bc.LogLevel                         = $DeserializedObject.LogLevel
        $bc.MaxLogSizeMB                     = $DeserializedObject.MaxLogSizeMB
        $bc.MaxLogsToKeep                    = $DeserializedObject.MaxLogsToKeep
        $bc.LogCommandHistory                = $DeserializedObject.LogCommandHistory
        $bc.CommandHistoryMaxLogSizeMB       = $DeserializedObject.CommandHistoryMaxLogSizeMB
        $bc.CommandHistoryMaxLogsToKeep      = $DeserializedObject.CommandHistoryMaxLogsToKeep
        $bc.BackendConfiguration             = $DeserializedObject.BackendConfiguration
        $bc.PluginConfiguration              = $DeserializedObject.PluginConfiguration
        $bc.BotAdmins                        = $DeserializedObject.BotAdmins
        $bc.CommandPrefix                    = $DeserializedObject.CommandPrefix
        $bc.AlternateCommandPrefixes         = $DeserializedObject.AlternateCommandPrefixes
        $bc.AlternateCommandPrefixSeperators = $DeserializedObject.AlternateCommandPrefixSeperators
        $bc.SendCommandResponseToPrivate     = $DeserializedObject.SendCommandResponseToPrivate
        $bc.MuteUnknownCommand               = $DeserializedObject.MuteUnknownCommand
        $bc.AddCommandReactions              = $DeserializedObject.AddCommandReactions
        $bc.DisallowDMs                      = $DeserializedObject.DisallowDMs
        $bc.FormatEnumerationLimitOverride   = $DeserializedObject.FormatEnumerationLimitOverride
        $bc.ChannelRules                     = [ChannelRule]::Serialize($DeserializedObject.ChannelRule)
        $bc.ApprovalConfiguration            = [ApprovalConfiguration]::Serialize($DeserializedObject.ApprovalConfiguration)

        return $bc
    }
}
