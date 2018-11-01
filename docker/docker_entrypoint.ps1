[cmdletbinding()]
param()

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

$VerbosePreference = 'Continue'

# SLACK_TOKEN and BOT_ADMINS environment variables are REQUIRED
# If they where not passed in then bail
$slackToken = Get-FromEnv -Name 'SLACK_TOKEN' -Default [string]::empty
$botAdmins  = Get-FromEnv -Name 'BOT_ADMINS'  -Default @([string]::empty)
if ([string]::IsNullOrEmpty($slackToken) -or $botAdmins.Count -eq 0) {
    throw 'Please specify your Slack token and initial list of bot administrators'
    #exit 1
}

Import-Module -Name PoshBot -ErrorAction Stop -Verbose:$false

$cmdPrefix          = Get-FromEnv -Name 'POSHBOT_CMD_PREFIX'            -Default '!'
$altCmdPrefixes     = Get-FromEnv -Name 'POSHBOT_ALT_CMD_PREFIXES'      -Default 'poshbot'
$altCmdPrefixes     = $altCmdPrefixes -split ';'
$pluginRepos        = Get-FromEnv -Name 'POSHBOT_PLUGIN_REPOSITORIES'   -Default 'PSGallery'
$pluginRepos = $pluginRepos -split ';'
$logDir             = Get-FromEnv -Name 'POSHBOT_LOG_DIR'               -Default "$rootDrive/poshbot_data/logs"
$botName            = Get-FromEnv -Name 'POSHBOT_NAME'                  -Default 'PoshBot_Docker'
$confDir            = Get-FromEnv -Name 'POSHBOT_CONF_DIR'              -Default "$rootDrive/poshbot_data"
$logLevel           = Get-FromEnv -Name 'POSHBOT_LOG_LEVEL'             -Default 'Verbose'
$pluginDir          = Get-FromEnv -Name 'POSHBOT_PLUGIN_DIR'            -Default "$rootDrive/poshbot_data/plugins"
$muteUnknownCommand = Get-FromEnv -Name 'POSHBOT_MUTE_UNKNOWN_CMD'      -Default $false
$manifestsToLoad    = Get-FromEnv -Name 'POSHBOT_MANIFESTS_TO_LOAD'     -Default @()
$manifestsToLoad = $manifestsToLoad -split ';'
$altCmdPrefixSep    = Get-FromEnv -Name 'POSHBOT_ALT_CMD_PREFIX_SEP'    -Default @(':',',',';')
$altCmdPrefixSep = $altCmdPrefixSep.ToCharArray()
$sendCmdRespToPriv  = Get-FromEnv -Name 'POSHBOT_SEND_CMD_RESP_TO_PRIV' -Default @()
$sendCmdRespToPriv = $sendCmdRespToPriv -split ';'

$configPSD1 = (Join-Path -Path $confDir -ChildPath 'PoshBot.psd1')
if (-not (Test-Path -Path $configPSD1)) {
    # Create the initial configuration
    $hash = @{
        Name                             = $botName
        ConfigurationDirectory           = $confDir
        CommandPrefix                    = $cmdPrefix
        PluginRepository                 = $pluginRepos
        LogDirectory                     = $logDir
        BotAdmins                        = $botAdmins
        BackendConfiguration             = @{
            Token = $slackToken
            Name  = 'SlackBackend'
        }
        LogLevel                         = $logLevel
        AlternateCommandPrefixes         = $altCmdPrefixes
        PluginDirectory                  = $pluginDir
        MuteUnknownCommand               = $muteUnknownCommand
        ModuleManifestsToLoad            = $manifestsToLoad
        AlternateCommandPrefixSeperators = $altCmdPrefixSep
        SendCommandResponseToPrivate     = $sendCmdRespToPriv
        PluginConfiguration = @{}
    }
    $config = New-PoshBotConfiguration @hash -Verbose
    if (-not (Test-Path -Path $confDir)) {
        New-Item -Path $confDir -ItemType Directory -Force > $null
    }
    $config | Save-PoshBotConfiguration -Path $configPSD1 -Force -Verbose
    $pbc = Get-PoshBotConfiguration -Path $configPSD1 -Verbose
} else {
    # There was a previous configuraiton
    # Merge any values from env vars into config
    $config = Import-PowerShellDataFile -Path $configPSD1
    $config.Name                             = $botName
    $config.ConfigurationDirectory           = $confDir
    $config.CommandPrefix                    = $cmdPrefix
    $config.PluginRepository                 = $pluginRepos
    $config.LogDirectory                     = $logDir
    $config.BotAdmins                        = $botAdmins
    $config.BackendConfiguration             = @{
        Token = $slackToken
        Name  = 'SlackBackend'
    }
    $config.LogLevel                         = $logLevel
    $config.AlternateCommandPrefixes         = $altCmdPrefixes
    $config.PluginDirectory                  = $pluginDir
    $config.MuteUnknownCommand               = $muteUnknownCommand
    $config.ModuleManifestsToLoad            = $manifestsToLoad
    $config.AlternateCommandPrefixSeperators = $altCmdPrefixSep
    $config.SendCommandResponseToPrivate     = $sendCmdRespToPriv

    $config | Save-PoshBotConfiguration -Path $configPSD1 -Force -Verbose
    $pbc = Get-PoshBotConfiguration -Path $configPSD1 -Verbose
}

$backend = New-PoshBotSlackBackend -Configuration $pbc.BackendConfiguration -Verbose
$bot = New-PoshBotInstance -Configuration $pbc -Backend $backend -Verbose
$bot.Start()
