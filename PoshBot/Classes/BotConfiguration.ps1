
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

    [MiddlewareConfiguration]$MiddlewareConfiguration = [MiddlewareConfiguration]::new()

    [BotConfiguration] SerializeInstance([PSObject]$DeserializedObject) {
        return [BotConfiguration]::Serialize($DeserializedObject)
    }

    [hashtable] ToHash() {
        $propertyNames = $this | Get-Member -MemberType Property | Select-Object -ExpandProperty Name
        $hash = @{}

        foreach ($property in $propertyNames) {
            if ($this.$property | Get-Member -MemberType Method -Name ToHash) {
                $hash.$property = $this.$property.ToHash()
            } else {
                $hash.$property = $this.$property
            }
        }

        return $hash
    }

    [BotConfiguration] Serialize([hashtable]$Hash) {

        $propertyNames = $this | Get-Member -MemberType Property | Select-Object -ExpandProperty Name

        $bc = [BotConfiguration]::new()

        foreach ($key in $Hash.keys) {
            if ($key -in $propertyNames) {

                $bc.Name                             = $hash.Name
                $bc.ConfigurationDirectory           = $hash.ConfigurationDirectory
                $bc.LogDirectory                     = $hash.LogDirectory
                $bc.PluginDirectory                  = $hash.PluginDirectory
                $bc.PluginRepository                 = $hash.PluginRepository
                $bc.ModuleManifestsToLoad            = $hash.ModuleManifestsToLoad
                $bc.LogLevel                         = $hash.LogLevel
                $bc.MaxLogSizeMB                     = $hash.MaxLogSizeMB
                $bc.MaxLogsToKeep                    = $hash.MaxLogsToKeep
                $bc.LogCommandHistory                = $hash.LogCommandHistory
                $bc.CommandHistoryMaxLogSizeMB       = $hash.CommandHistoryMaxLogSizeMB
                $bc.CommandHistoryMaxLogsToKeep      = $hash.CommandHistoryMaxLogsToKeep
                $bc.BackendConfiguration             = $hash.BackendConfiguration
                $bc.PluginConfiguration              = $hash.PluginConfiguration
                $bc.BotAdmins                        = $hash.BotAdmins
                $bc.CommandPrefix                    = $hash.CommandPrefix
                $bc.AlternateCommandPrefixes         = $hash.AlternateCommandPrefixes
                $bc.AlternateCommandPrefixSeperators = $hash.AlternateCommandPrefixSeperators
                $bc.SendCommandResponseToPrivate     = $hash.SendCommandResponseToPrivate
                $bc.MuteUnknownCommand               = $hash.MuteUnknownCommand
                $bc.AddCommandReactions              = $hash.AddCommandReactions
                $bc.DisallowDMs                      = $hash.DisallowDMs
                $bc.FormatEnumerationLimitOverride   = $hash.FormatEnumerationLimitOverride
                $bc.ChannelRules                     = $hash.ChannelRules.ForEach({[ChannelRule]::Serialize($_)})
                $bc.ApprovalConfiguration            = [ApprovalConfiguration]::Serialize($hash.ApprovalConfiguration)
                $bc.MiddlewareConfiguration          = [MiddlewareConfiguration]::Serialize($hash.MiddlewareConfiguration)
            } else {
                throw "Hash key [$key] is not a property in BotConfiguration"
            }
        }

        return $bc
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
        $bc.ChannelRules                     = $DeserializedObject.ChannelRules.Foreach({[ChannelRule]::Serialize($_)})
        $bc.ApprovalConfiguration            = [ApprovalConfiguration]::Serialize($DeserializedObject.ApprovalConfiguration)
        $bc.MiddlewareConfiguration          = [MiddlewareConfiguration]::Serialize($DeserializedObject.MiddlewareConfiguration)

        return $bc
    }
}
