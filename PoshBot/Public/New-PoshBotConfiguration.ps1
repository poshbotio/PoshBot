
function New-PoshBotConfiguration {
    <#
    .SYNOPSIS
        Creates a new PoshBot configuration object.
    .DESCRIPTION
        Creates a new PoshBot configuration object.
    .PARAMETER Name
        The name the bot instance will be known as.
    .PARAMETER ConfigurationDirectory
        The directory when PoshBot configuration data will be written to.
    .PARAMETER LogDirectory
        The log directory logs will be written to.
    .PARAMETER PluginDirectory
        The directory PoshBot will look for PowerShell modules.
        This path will be prepended to your $env:PSModulePath.
    .PARAMETER PluginRepository
        One or more PowerShell repositories to look in when installing new plugins (modules).
        These will be the repository name(s) as found in Get-PSRepository.
    .PARAMETER ModuleManifestsToLoad
        One or more paths to module manifest (.psd1) files. These modules will be automatically
        loaded when PoshBot starts.
    .PARAMETER LogLevel
        The level of logging that PoshBot will do.
    .PARAMETER MaxLogSizeMB
        The maximum log file size in megabytes.
    .PARAMETER MaxLogsToKeep
        The maximum number of logs to keep. Once this value is reached, logs will start rotating.
    .PARAMETER LogCommandHistory
        Enable command history to be logged to a separate file for convenience. The default it $true
    .PARAMETER CommandHistoryMaxLogSizeMB
        The maximum log file size for the command history
    .PARAMETER CommandHistoryMaxLogsToKeep
        The maximum number of logs to keep for command history. Once this value is reached, the logs will start rotating.
    .PARAMETER BackendConfiguration
        A hashtable of configuration options required by the backend chat network implementation.
    .PARAMETER PluginConfiguration
        A hashtable of configuration options used by the various plugins (modules) that are installed in PoshBot.
        Each key in the hashtable must be the name of a plugin. The value of that hashtable item will be another hashtable
        with each key matching a parameter name in one or more commands of that module. A plugin command can specifiy that a
        parameter gets its value from this configuration by applying the custom attribute [PoshBot.FromConfig()] on
        the parameter.

        The function below is stating that the parameter $MyParam will get its value from the plugin configuration. The user
        running this command in PoshBot does not need to specify this parameter. PoshBot will dynamically resolve and apply
        the matching value from the plugin configuration when the command is executed.

        function Get-Foo {
            [cmdletbinding()]
            param(
                [PoshBot.FromConfig()]
                [parameter(mandatory)]
                [string]$MyParam
            )

            Write-Output $MyParam
        }

        If the function below was part of the Demo plugin, PoshBot will look in the plugin configuration for a key matching Demo
        and a child key matching $MyParam.

        Example plugin configuration:
        @{
            Demo = @{
                MyParam = 'bar'
            }
        }
    .PARAMETER BotAdmins
        An array of chat handles that will be granted admin rights in PoshBot. Any user in this array will have full rights in PoshBot. At startup,
        PoshBot will resolve these handles into IDs given by the chat network.
    .PARAMETER CommandPrefix
        The prefix (single character) that must be specified in front of a command in order for PoshBot to recognize the chat message as a bot command.

        !get-foo --value bar
    .PARAMETER AlternateCommandPrefixes
        Some users may want to specify alternate prefixes when calling bot comamnds. Use this parameter to specify an array of words that PoshBot
        will also check when parsing a chat message.

        bender get-foo --value bar

        hal open-doors --type pod
    .PARAMETER AlternateCommandPrefixSeperators
        An array of characters that can also ben used when referencing bot commands.

        bender, get-foo --value bar

        hal; open-doors --type pod
    .PARAMETER SendCommandResponseToPrivate
        A list of fully qualified (<PluginName>:<CommandName>) plugin commands that will have their responses redirected back to a direct message
        channel with the calling user rather than a shared channel.

        @(
            demo:get-foo
            network:ping
        )
    .PARAMETER MuteUnknownCommand
        Instead of PoshBot returning a warning message when it is unable to find a command, use this to parameter to tell PoshBot to return nothing.
    .PARAMETER AddCommandReactions
        Add reactions to a chat message indicating the command is being executed, has succeeded, or failed.
    .PARAMETER ApprovalExpireMinutes
        The amount of time (minutes) that a command the requires approval will be pending until it expires.
    .PARAMETER DisallowDMs
        Disallow DMs (direct messages) with the bot. If a user tries to DM the bot it will be ignored.
    .PARAMETER FormatEnumerationLimitOverride
        Set $FormatEnumerationLimit to this.  Defaults to unlimited (-1)

        Determines how many enumerated items are included in a display.
        This variable does not affect the underlying objects; just the display.
        When the value of $FormatEnumerationLimit is less than the number of enumerated items, PowerShell adds an ellipsis (...) to indicate items not shown.
    .PARAMETER ApprovalCommandConfigurations
        Array of hashtables containing command approval configurations.

        @(
            @{
                Expression = 'MyModule:Execute-Deploy:*'
                Groups = 'platform-admins'
                PeerApproval = $true
            }
            @{
                Expression = 'MyModule:Deploy-HRApp:*'
                Groups = @('platform-managers', 'hr-managers')
                PeerApproval = $true
            }
        )
    .PARAMETER ChannelRules
        Array of channels rules that control what plugin commands are allowed in a channel. Wildcards are supported.
        Channel names that match against this list will be allowed to have Poshbot commands executed in them.

        Internally this uses the `-like` comparison operator, not `-match`. Regexes are not allowed.

        For best results, list channels and commands from most specific to least specific. PoshBot will
        evaluate the first match found.

        Note that the bot will still receive messages from all channels it is a member of. These message MAY
        be logged depending on your configured logging level.

        Example value:
        @(
            # Only allow builtin commands in the 'botadmin' channel
            @{
                Channel = 'botadmin'
                IncludeCommands = @('builtin:*')
                ExcludeCommands = @()
            }
            # Exclude builtin commands from any "projectX" channel
            @{
                Channel = '*projectx*'
                IncludeCommands = @('*')
                ExcludeCommands = @('builtin:*')
            }
            # It's the wild west in random, except giphy :)
            @{
                Channel = 'random'
                IncludeCommands = @('*')
                ExcludeCommands = @('*giphy*')
            }
            # All commands are otherwise allowed
            @{
                Channel = '*'
                IncludeCommands = @('*')
                ExcludeCommands = @()
            }
        )
    .PARAMETER PreReceiveMiddlewareHooks
        Array of middleware scriptblocks that will run before PoshBot "receives" the message from the backend implementation.
        This middleware will receive the original message sent from the chat network and have a chance to modify, analyze, and optionally drop the message before PoshBot continues processing it.
    .PARAMETER PostReceiveMiddlewareHooks
        Array of middleware scriptblocks that will run after a message is "received" from the backend implementation.
        This middleware runs after messages have been parsed and matched with a registered command in PoshBot.
    .PARAMETER PreExecuteMiddlewareHooks
        Array of middleware scriptblocks that will run before a command is executed.
        This middleware is a good spot to run extra authentication or validation processes before commands are executed.
    .PARAMETER PostExecuteMiddlewareHooks
        Array of middleware scriptblocks that will run after PoshBot commands have been executed.
        This middleware is a good spot for custom logging solutions to write command history to a custom location.
    .PARAMETER PreResponseMiddlewareHooks
        Array of middleware scriptblocks that will run before command responses are sent to the backend implementation.
        This middleware is a good spot for modifying or sanitizing responses before they are sent to the chat network.
    .PARAMETER PostResponseMiddlewareHooks
        Array of middleware scriptblocks that will run after command responses have been sent to the backend implementation.
        This middleware runs after all processing is complete for a command and is a good spot for additional custom logging.
    .EXAMPLE
        PS C:\> New-PoshBotConfiguration -Name Cherry2000 -AlternateCommandPrefixes @('Cherry', 'Sam')

        Name                             : Cherry2000
        ConfigurationDirectory           : C:\Users\brand\.poshbot
        LogDirectory                     : C:\Users\brand\.poshbot
        PluginDirectory                  : C:\Users\brand\.poshbot
        PluginRepository                 : {PSGallery}
        ModuleManifestsToLoad            : {}
        LogLevel                         : Verbose
        BackendConfiguration             : {}
        PluginConfiguration              : {}
        BotAdmins                        : {}
        CommandPrefix                    : !
        AlternateCommandPrefixes         : {Cherry, Sam}
        AlternateCommandPrefixSeperators : {:, ,, ;}
        SendCommandResponseToPrivate     : {}
        MuteUnknownCommand               : False
        AddCommandReactions              : True
        ApprovalConfiguration            : ApprovalConfiguration

        Create a new PoshBot configuration with default values except for the bot name and alternate command prefixes that it will listen for.
    .EXAMPLE
        PS C:\> $backend = @{Name = 'SlackBackend'; Token = 'xoxb-569733935137-njOPkyBThqOTTUnCZb7tZpKK'}
        PS C:\> $botParams = @{
                    Name = 'HAL9000'
                    LogLevel = 'Info'
                    BotAdmins = @('JoeUser')
                    BackendConfiguration = $backend
                }
        PS C:\> $myBotConfig = New-PoshBotConfiguration @botParams
        PS C:\> $myBotConfig

        Name                             : HAL9000
        ConfigurationDirectory           : C:\Users\brand\.poshbot
        LogDirectory                     : C:\Users\brand\.poshbot
        PluginDirectory                  : C:\Users\brand\.poshbot
        PluginRepository                 : {MyLocalRepo}
        ModuleManifestsToLoad            : {}
        LogLevel                         : Info
        BackendConfiguration             : {}
        PluginConfiguration              : {}
        BotAdmins                        : {JoeUser}
        CommandPrefix                    : !
        AlternateCommandPrefixes         : {poshbot}
        AlternateCommandPrefixSeperators : {:, ,, ;}
        SendCommandResponseToPrivate     : {}
        MuteUnknownCommand               : False
        AddCommandReactions              : True
        ApprovalConfiguration            : ApprovalConfiguration

        PS C:\> $myBotConfig | Start-PoshBot -AsJob

        Create a new PoshBot configuration with a Slack backend. Slack's backend only requires a bot token to be specified. Ensure the person
        with Slack handle 'JoeUser' is a bot admin.
    .OUTPUTS
        BotConfiguration
    .LINK
        Get-PoshBotConfiguration
    .LINK
        Save-PoshBotConfiguration
    .LINK
        New-PoshBotInstance
    .LINK
        Start-PoshBot
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope='Function', Target='*')]
    [cmdletbinding()]
    param(
        [string]$Name = 'PoshBot',
        [string]$ConfigurationDirectory = $script:defaultPoshBotDir,
        [string]$LogDirectory = $script:defaultPoshBotDir,
        [string]$PluginDirectory = $script:defaultPoshBotDir,
        [string[]]$PluginRepository = @('PSGallery'),
        [string[]]$ModuleManifestsToLoad = @(),
        [LogLevel]$LogLevel = [LogLevel]::Verbose,
        [int]$MaxLogSizeMB = 10,
        [int]$MaxLogsToKeep = 5,
        [bool]$LogCommandHistory = $true,
        [int]$CommandHistoryMaxLogSizeMB = 10,
        [int]$CommandHistoryMaxLogsToKeep = 5,
        [hashtable]$BackendConfiguration = @{},
        [hashtable]$PluginConfiguration = @{},
        [string[]]$BotAdmins = @(),
        [char]$CommandPrefix = '!',
        [string[]]$AlternateCommandPrefixes = @('poshbot'),
        [char[]]$AlternateCommandPrefixSeperators = @(':', ',', ';'),
        [string[]]$SendCommandResponseToPrivate = @(),
        [bool]$MuteUnknownCommand = $false,
        [bool]$AddCommandReactions = $true,
        [int]$ApprovalExpireMinutes = 30,
        [switch]$DisallowDMs,
        [int]$FormatEnumerationLimitOverride = -1,
        [hashtable[]]$ApprovalCommandConfigurations = @(),
        [hashtable[]]$ChannelRules = @(),
        [MiddlewareHook[]]$PreReceiveMiddlewareHooks   = @(),
        [MiddlewareHook[]]$PostReceiveMiddlewareHooks  = @(),
        [MiddlewareHook[]]$PreExecuteMiddlewareHooks   = @(),
        [MiddlewareHook[]]$PostExecuteMiddlewareHooks  = @(),
        [MiddlewareHook[]]$PreResponseMiddlewareHooks  = @(),
        [MiddlewareHook[]]$PostResponseMiddlewareHooks = @()
    )

    Write-Verbose -Message 'Creating new PoshBot configuration'
    $config = [BotConfiguration]::new()
    $config.Name = $Name
    $config.ConfigurationDirectory = $ConfigurationDirectory
    $config.AlternateCommandPrefixes = $AlternateCommandPrefixes
    $config.AlternateCommandPrefixSeperators = $AlternateCommandPrefixSeperators
    $config.BotAdmins = $BotAdmins
    $config.CommandPrefix = $CommandPrefix
    $config.LogDirectory = $LogDirectory
    $config.LogLevel = $LogLevel
    $config.MaxLogSizeMB = $MaxLogSizeMB
    $config.MaxLogsToKeep = $MaxLogsToKeep
    $config.LogCommandHistory = $LogCommandHistory
    $config.CommandHistoryMaxLogSizeMB = $CommandHistoryMaxLogSizeMB
    $config.CommandHistoryMaxLogsToKeep = $CommandHistoryMaxLogsToKeep
    $config.BackendConfiguration = $BackendConfiguration
    $config.PluginConfiguration = $PluginConfiguration
    $config.ModuleManifestsToLoad = $ModuleManifestsToLoad
    $config.MuteUnknownCommand = $MuteUnknownCommand
    $config.PluginDirectory = $PluginDirectory
    $config.PluginRepository = $PluginRepository
    $config.SendCommandResponseToPrivate = $SendCommandResponseToPrivate
    $config.AddCommandReactions = $AddCommandReactions
    $config.ApprovalConfiguration.ExpireMinutes = $ApprovalExpireMinutes
    $config.DisallowDMs = ($DisallowDMs -eq $true)
    $config.FormatEnumerationLimitOverride = $FormatEnumerationLimitOverride
    if ($ChannelRules.Count -ge 1) {
        $config.ChannelRules = $null
        foreach ($item in $ChannelRules) {
            $config.ChannelRules += [ChannelRule]::new($item.Channel, $item.IncludeCommands, $item.ExcludeCommands)
        }
    }
    if ($ApprovalCommandConfigurations.Count -ge 1) {
        foreach ($item in $ApprovalCommandConfigurations) {
            $acc = [ApprovalCommandConfiguration]::new()
            $acc.Expression = $item.Expression
            $acc.ApprovalGroups = $item.Groups
            $acc.PeerApproval = $item.PeerApproval
            $config.ApprovalConfiguration.Commands.Add($acc) > $null
        }
    }

    # Add any middleware hooks
    foreach ($type in [enum]::GetNames([MiddlewareType])) {
        foreach ($item in $PSBoundParameters["$($type)MiddlewareHooks"]) {
            $config.MiddlewareConfiguration.Add($item, $type)
        }
    }

    $config
}

Export-ModuleMember -Function 'New-PoshBotConfiguration'
