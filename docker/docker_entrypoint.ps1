[cmdletbinding()]
param()

$VerbosePreference = 'Continue'

function Get-FromEnv {
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Name,

        [parameter(Mandatory)]
        $Default
    )

    $envValue = Get-ChildItem -Path Env: |
        Where-Object { $_.Name.ToUpper() -eq $Name.ToUpper() } |
        Select-Object -First 1 |
        ForEach-Object {
            $_.Value
        }
    if ($null -eq $envValue) {
        Write-Verbose "$Name = $($Default)"
        $Default
    } else {
        Write-Verbose "$Name = $envValue"
        $envValue
    }
}

if ($IsLinux -or $IsMacOs) {
    $rootDrive = ''
} else {
    $rootDrive = 'c:'
}

# List of settings that are exposed as environment variables and will
# be used to either set the initial configuration if no PoshBot configuration
# file is present, or override the existing configuration setting
$configurationSettings = @{
    Name = @{
        EnvVariable  = 'POSHBOT_NAME'
        DefaultValue = 'PoshBot_Docker'
    }
    ConfigurationDirectory = @{
        EnvVariable  = 'POSHBOT_CONFIG_DIRECTORY'
        DefaultValue = "$rootDrive/poshbot_data"
    }
    LogDirectory = @{
        EnvVariable  = 'POSHBOT_LOG_DIRECTORY'
        DefaultValue = "$rootDrive/poshbot_data/logs"
    }
    PluginDirectory = @{
        EnvVariable  = 'POSHBOT_PLUGIN_DIRECTORY'
        DefaultValue = "$rootDrive/poshbot_data/plugins"
    }
    PluginRepository = @{
        EnvVariable  = 'POSHBOT_PLUGIN_REPOSITORIES'
        DefaultValue = @('PSGallery')
    }
    # ModuleManifestsToLoad = @{
    #     EnvVariable  = 'POSHBOT_MODULE_MANIFESTS_TO_LOAD'
    #     DefaultValue = @()
    # }
    LogLevel = @{
        EnvVariable  = 'POSHBOT_LOG_LEVEL'
        DefaultValue = 'Verbose'
    }
    MaxLogSizeMB = @{
        EnvVariable  = 'POSHBOT_MAX_LOG_SIZE_MB'
        DefaultValue = 10
    }
    MaxLogsToKeep = @{
        EnvVariable  = 'POSHBOT_MAX_LOGS_TO_KEEP'
        DefaultValue = 5
    }
    LogCommandHistory = @{
        EnvVariable  = 'POSHBOT_LOG_CMD_HISTORY'
        DefaultValue = $true
    }
    CommandHistoryMaxLogSizeMB = @{
        EnvVariable  = 'POSHBOT_CMD_HISTORY_MAX_LOG_SIZE_MB'
        DefaultValue = 10
    }
    CommandHistoryMaxLogsToKeep = @{
        EnvVariable  = 'POSHBOT_CMD_HISTORY_MAX_LOGS_TO_KEEP'
        DefaultValue = 5
    }
    BackendConfiguration = @{
        EnvVariable  = 'POSHBOT_BACKEND_CONFIGURATION'
        DefaultValue = @{}
    }
    PluginConfiguration = @{
        EnvVariable  = 'POSHBOT_PLUGIN_CONFIGURATION'
        DefaultValue = @{}
    }
    BotAdmins = @{
        EnvVariable  = 'POSHBOT_ADMINS'
        DefaultValue = @()
    }
    CommandPrefix = @{
        EnvVariable  = 'POSHBOT_CMD_PREFIX'
        DefaultValue = '!'
    }
    AlternateCommandPrefixes = @{
        EnvVariable  = 'POSHBOT_ALT_CMD_PREFIXES'
        DefaultValue = @('poshbot')
    }
    AlternateCommandPrefixSeperators = @{
        EnvVariable  = 'POSHBOT_ALT_CMD_PREFIX_SEP'
        DefaultValue = @(':', ',', ';')
    }
    SendCommandResponseToPrivate = @{
        EnvVariable  = 'POSHBOT_SEND_CMD_RESP_TO_PRIV'
        DefaultValue = @()
    }
    MuteUnknownCommand = @{
        EnvVariable  = 'POSHBOT_MUTE_UNKNOWN_CMD'
        DefaultValue = $false
    }
    AddCommandReactions = @{
        EnvVariable  = 'POSHBOT_ADD_CMD_REACTIONS'
        DefaultValue = $true
    }
    DisallowDMs = @{
        EnvVariable  = 'POSHBOT_DISALLOW_DMS'
        DefaultValue = $false
    }
    FormatEnumerationLimitOverride = @{
        EnvVariable  = 'POSHBOT_FORMAT_ENUMERATION_LIMIT'
        DefaultValue = -1
    }
    ConfigDir = @{
        EnvVariable  = 'POSHBOT_CONF_DIR'
        DefaultValue = "$rootDrive/poshbot_data"
    }
    BackendType = @{
        EnvVariable  = 'POSHBOT_BACKEND'
        DefaultValue = 'SlackBackend'
    }
}

Import-Module -Name PoshBot -ErrorAction Stop -Verbose:$false

# Create runtime settings by attempting to retrieve values for
# configuration settings from environment variables
# Use default value if environment variable is not defined
$runTimeSettings = @{}
$configurationSettings.GetEnumerator().ForEach({
    $runTimeSettings.($_.Name) = Get-FromEnv -Name $_.Value.EnvVariable -Default $_.Value.DefaultValue
})

# Some settings are defined in environments variables slightly differently
# than what is needed by PoshBot (arrays in configuration are passed as semi-colon ';' separated strings for example)
if ($env:POSHBOT_ALT_CMD_PREFIXES)          { $runTimeSettings.AlternateCommandPrefixes         = $runTimeSettings.AlternateCommandPrefixes -split ';' }
if ($env:POSHBOT_PLUGIN_REPOSITORIES)       { $runTimeSettings.PluginRepository                 = $runTimeSettings.PluginRepository         -split ';' }
#if ($env:POSHBOT_MODULE_MANIFESTS_TO_LOAD)  { $runTimeSettings.ModuleManifestsToLoad            = $runTimeSettings.ModuleManifestsToLoad    -split ';' }
if ($env:POSHBOT_ALT_CMD_PREFIX_SEP)        { $runTimeSettings.AlternateCommandPrefixSeperators = ($runTimeSettings.AlternateCommandPrefixSeperators -split ';').ToCharArray }

$configPSD1 = Join-Path -Path $runTimeSettings.ConfigDir -ChildPath 'PoshBot.psd1'
if (-not (Test-Path -Path $configPSD1)) {

    # Create the initial configuration minus the backend
    $configParams = @{
        Name                             = $runtimeSettings.Name
        ConfigurationDirectory           = $runtimeSettings.ConfigurationDirectory
        LogDirectory                     = $runtimeSettings.LogDirectory
        PluginDirectory                  = $runtimeSettings.PluginDirectory
        PluginRepository                 = $runtimeSettings.PluginRepository
        #ModuleManifestsToLoad            = $runtimeSettings.ModuleManifestsToLoad
        LogLevel                         = $runtimeSettings.LogLevel
        MaxLogSizeMB                     = $runtimeSettings.MaxLogSizeMB
        MaxLogsToKeep                    = $runtimeSettings.MaxLogsToKeep
        LogCommandHistory                = $runtimeSettings.LogCommandHistory
        CommandHistoryMaxLogSizeMB       = $runtimeSettings.CommandHistoryMaxLogSizeMB
        CommandHistoryMaxLogsToKeep      = $runtimeSettings.CommandHistoryMaxLogsToKeep
        BotAdmins                        = $runtimeSettings.BotAdmins
        CommandPrefix                    = $runtimeSettings.CommandPrefix
        AlternateCommandPrefixes         = $runtimeSettings.AlternateCommandPrefixes
        AlternateCommandPrefixSeperators = $runtimeSettings.AlternateCommandPrefixSeperators
        MuteUnknownCommand               = $runTimeSettings.MuteUnknownCommand
    }

    # Create PoshBot config for the first time
    if ($runTimeSettings.BackendType -eq 'SlackBackend') {
        # POSHBOT_SLACK_TOKEN and POSHBOT_ADMINS environment variables are REQUIRED.
        # If they where not passed in then bail.
        $slackToken = Get-FromEnv -Name 'POSHBOT_SLACK_TOKEN' -Default ''
        if ([string]::IsNullOrEmpty($slackToken) -or $runtimeSettings.BotAdmins.Count -eq 0) {
            throw 'POSHBOT_SLACK_TOKEN and POSHBOT_ADMINS environment variables are required if there is not a preexisting bot configuration to load. Please specify your Slack token and initial list of bot administrators.'
            exit 1
        }
        $configParams.BackendConfiguration = @{
            Token = $slackToken
            Name  = 'SlackBackend'
        }
    } elseif ($runTimeSettings.BackendType -eq 'TeamsBackend') {
        # Validate require environment variables for a Teams backend
        $botName                 = Get-FromEnv -Name 'POSHBOT_TEAMS_BOT_NAME'                   -Default ''
        $teamsId                 = Get-FromEnv -Name 'POSHBOT_TEAMS_ID'                         -Default ''
        $serviceBusNamespace     = Get-FromEnv -Name 'POSHBOT_TEAMS_SERVICEBUS_NAMESPACE'       -Default ''
        $serviceBusQueueName     = Get-FromEnv -Name 'POSHBOT_TEAMS_SERVICEBUS_QUEUE_NAME'      -Default ''
        $serviceBusAccessKeyName = Get-FromEnv -Name 'POSHBOT_TEAMS_SERVICEBUS_ACCESS_KEY_NAME' -Default ''
        $serviceBusAccessKey     = Get-FromEnv -Name 'POSHBOT_TEAMS_SERVICEBUS_ACCESS_KEY'      -Default ''
        $botFrameworkId          = Get-FromEnv -Name 'POSHBOT_BOT_FRAMEWORK_ID'                 -Default ''
        $botFrameworkPassword    = Get-FromEnv -Name 'POSHBOT_BOT_FRAMEWORK_PASSWORD'           -Default ''

        if ($runtimeSettings.BotAdmins.Count -eq 0 -or
            [string]::IsNullOrEmpty($botName) -or
            [string]::IsNullOrEmpty($teamsId) -or
            [string]::IsNullOrEmpty($serviceBusNamespace) -or
            [string]::IsNullOrEmpty($serviceBusQueueName) -or
            [string]::IsNullOrEmpty($serviceBusAccessKeyName) -or
            [string]::IsNullOrEmpty($serviceBusAccessKey) -or
            [string]::IsNullOrEmpty($botFrameworkId) -or
            [string]::IsNullOrEmpty($botFrameworkPassword)) {

            throw 'POSHBOT_SLACK_TOKEN and POSHBOT_ADMINS environment variables are required if there is not a preexisting bot configuration to load. Please specify your Slack token and initial list of bot administrators.'
            exit 1
        }
        $configParams.BackendConfiguration = @{
            Name                = 'TeamsBackend'
            BotName             = $botName
            TeamId              = $teamsId
            ServiceBusNamespace = $serviceBusNamespace
            QueueName           = $serviceBusQueueName
            AccessKeyName       = $serviceBusAccessKeyName
            AccessKey           = $serviceBusAccessKey | ConvertTo-SecureString -AsPlainText -Force
            Credential          = [pscredential]::new(
                $botFrameworkId,
                ($botFrameworkPassword | ConvertTo-SecureString -AsPlainText -Force)
            )
        }
    }

    $pbc = New-PoshBotConfiguration @configParams -Verbose
    # if (-not (Test-Path -Path $runTimeSettings.ConfigDir)) {
    #     New-Item -Path $runTimeSettings.ConfigDir -ItemType Directory -Force > $null
    # }
    # $config | Save-PoshBotConfiguration -Path $configPSD1 -Force -Verbose
    # $pbc = Get-PoshBotConfiguration -Path $configPSD1 -Verbose
} else {
    # There was a previous configuraiton
    # Merge any values from env vars into config
    $pbc = Get-PoshBotConfiguration -Path $configPSD1
    $pbc.Name                             = Get-FromEnv -Name 'POSHBOT_NAME'                     -Default $pbc.Name
    $pbc.ConfigurationDirectory           = Get-FromEnv -Name 'POSHBOT_CONF_DIR'                 -Default $pbc.ConfigurationDirectory
    $pbc.CommandPrefix                    = Get-FromEnv -Name 'POSHBOT_CMD_PREFIX'               -Default $pbc.CommandPrefix
    $pbc.PluginRepository                 = Get-FromEnv -Name 'POSHBOT_PLUGIN_REPOSITORIES'      -Default $pbc.PluginRepository
    $pbc.LogDirectory                     = Get-FromEnv -Name 'POSHBOT_LOG_DIR'                  -Default $pbc.LogDirectory
    $pbc.BotAdmins                        = Get-FromEnv -Name 'BOT_ADMINS'                       -Default $pbc.BotAdmins
    $pbc.LogLevel                         = Get-FromEnv -Name 'POSHBOT_LOG_LEVEL'                -Default $pbc.LogLevel
    $pbc.AlternateCommandPrefixes         = Get-FromEnv -Name 'POSHBOT_ALT_CMD_PREFIXES'         -Default $pbc.AlternateCommandPrefixes
    $pbc.PluginDirectory                  = Get-FromEnv -Name 'POSHBOT_PLUGIN_DIR'               -Default $pbc.PluginDirectory
    $pbc.MuteUnknownCommand               = Get-FromEnv -Name 'POSHBOT_MUTE_UNKNOWN_CMD'         -Default $pbc.MuteUnknownCommand
    #$pbc.ModuleManifestsToLoad            = Get-FromEnv -Name 'POSHBOT_MANIFESTS_TO_LOAD'        -Default $pbc.ModuleManifestsToLoad
    $pbc.AlternateCommandPrefixSeperators = Get-FromEnv -Name 'POSHBOT_ALT_CMD_PREFIX_SEP'       -Default $pbc.AlternateCommandPrefixSeperators
    $pbc.SendCommandResponseToPrivate     = Get-FromEnv -Name 'POSHBOT_SEND_CMD_RESP_TO_PRIV'    -Default $pbc.SendCommandResponseToPrivate

    $slackToken = Get-FromEnv -Name 'SLACK_TOKEN' -Default ''
    if (-not [string]::IsNullOrEmpty($slackToken)) {
        $pbc.BackendConfiguration = @{
            Token = $slackToken
            Name  = 'SlackBackend'
        }
    }
}

# Create backend based on configured backend type (Slack, Teams)
if ($runTimeSettings.BackendType -in @('Slack', 'SlackBackend')) {
    $backend = New-PoshBotSlackBackend -Configuration $pbc.BackendConfiguration
} elseIf ($runTimeSettings.BackendType -in @('Teams', 'TeamsBackend')) {
    $backend = New-PoshBotTeamsBackend -Configuration $pbc.BackendConfiguration
} else {
    throw "Unable to determine backend type. Name property in BackendConfiguration should have a value of 'Slack', 'SlackBackend', 'Teams', or 'TeamsBackend'"
    exit 1
}

$bot = New-PoshBotInstance -Configuration $pbc -Backend $backend
$bot.Start()
