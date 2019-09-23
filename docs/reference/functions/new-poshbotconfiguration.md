---
external help file: PoshBot-help.xml
Module Name: poshbot
online version:
schema: 2.0.0
---

# New-PoshBotConfiguration

## SYNOPSIS
Creates a new PoshBot configuration object.

## SYNTAX

```
New-PoshBotConfiguration [[-Name] <String>] [[-ConfigurationDirectory] <String>] [[-LogDirectory] <String>]
 [[-PluginDirectory] <String>] [[-PluginRepository] <String[]>] [[-ModuleManifestsToLoad] <String[]>]
 [[-LogLevel] <LogLevel>] [[-MaxLogSizeMB] <Int32>] [[-MaxLogsToKeep] <Int32>] [[-LogCommandHistory] <Boolean>]
 [[-CommandHistoryMaxLogSizeMB] <Int32>] [[-CommandHistoryMaxLogsToKeep] <Int32>]
 [[-BackendConfiguration] <Hashtable>] [[-PluginConfiguration] <Hashtable>] [[-BotAdmins] <String[]>]
 [[-CommandPrefix] <Char>] [[-AlternateCommandPrefixes] <String[]>]
 [[-AlternateCommandPrefixSeperators] <Char[]>] [[-SendCommandResponseToPrivate] <String[]>]
 [[-MuteUnknownCommand] <Boolean>] [[-AddCommandReactions] <Boolean>] [[-ApprovalExpireMinutes] <Int32>]
 [-DisallowDMs] [[-FormatEnumerationLimitOverride] <Int32>] [[-ApprovalCommandConfigurations] <Hashtable[]>]
 [[-ChannelRules] <Hashtable[]>] [[-PreReceiveMiddlewareHooks] <MiddlewareHook[]>]
 [[-PostReceiveMiddlewareHooks] <MiddlewareHook[]>] [[-PreExecuteMiddlewareHooks] <MiddlewareHook[]>]
 [[-PostExecuteMiddlewareHooks] <MiddlewareHook[]>] [[-PreResponseMiddlewareHooks] <MiddlewareHook[]>]
 [[-PostResponseMiddlewareHooks] <MiddlewareHook[]>] [<CommonParameters>]
```

## DESCRIPTION
Creates a new PoshBot configuration object.

## EXAMPLES

### EXAMPLE 1
```
New-PoshBotConfiguration -Name Cherry2000 -AlternateCommandPrefixes @('Cherry', 'Sam')
```

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

### EXAMPLE 2
```
$backend = @{Name = 'SlackBackend'; Token = 'xoxb-569733935137-njOPkyBThqOTTUnCZb7tZpKK'}
```

PS C:\\\> $botParams = @{
            Name = 'HAL9000'
            LogLevel = 'Info'
            BotAdmins = @('JoeUser')
            BackendConfiguration = $backend
        }
PS C:\\\> $myBotConfig = New-PoshBotConfiguration @botParams
PS C:\\\> $myBotConfig

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

PS C:\\\> $myBotConfig | Start-PoshBot -AsJob

Create a new PoshBot configuration with a Slack backend.
Slack's backend only requires a bot token to be specified.
Ensure the person
with Slack handle 'JoeUser' is a bot admin.

## PARAMETERS

### -Name
The name the bot instance will be known as.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: PoshBot
Accept pipeline input: False
Accept wildcard characters: False
```

### -ConfigurationDirectory
The directory when PoshBot configuration data will be written to.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: $script:defaultPoshBotDir
Accept pipeline input: False
Accept wildcard characters: False
```

### -LogDirectory
The log directory logs will be written to.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: $script:defaultPoshBotDir
Accept pipeline input: False
Accept wildcard characters: False
```

### -PluginDirectory
The directory PoshBot will look for PowerShell modules.
This path will be prepended to your $env:PSModulePath.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: $script:defaultPoshBotDir
Accept pipeline input: False
Accept wildcard characters: False
```

### -PluginRepository
One or more PowerShell repositories to look in when installing new plugins (modules).
These will be the repository name(s) as found in Get-PSRepository.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: @('PSGallery')
Accept pipeline input: False
Accept wildcard characters: False
```

### -ModuleManifestsToLoad
One or more paths to module manifest (.psd1) files.
These modules will be automatically
loaded when PoshBot starts.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: @()
Accept pipeline input: False
Accept wildcard characters: False
```

### -LogLevel
The level of logging that PoshBot will do.

```yaml
Type: LogLevel
Parameter Sets: (All)
Aliases:
Accepted values: Info, Verbose, Debug

Required: False
Position: 7
Default value: Verbose
Accept pipeline input: False
Accept wildcard characters: False
```

### -MaxLogSizeMB
The maximum log file size in megabytes.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 8
Default value: 10
Accept pipeline input: False
Accept wildcard characters: False
```

### -MaxLogsToKeep
The maximum number of logs to keep.
Once this value is reached, logs will start rotating.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 9
Default value: 5
Accept pipeline input: False
Accept wildcard characters: False
```

### -LogCommandHistory
Enable command history to be logged to a separate file for convenience.
The default it $true

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 10
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### -CommandHistoryMaxLogSizeMB
The maximum log file size for the command history

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 11
Default value: 10
Accept pipeline input: False
Accept wildcard characters: False
```

### -CommandHistoryMaxLogsToKeep
The maximum number of logs to keep for command history.
Once this value is reached, the logs will start rotating.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 12
Default value: 5
Accept pipeline input: False
Accept wildcard characters: False
```

### -BackendConfiguration
A hashtable of configuration options required by the backend chat network implementation.

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 13
Default value: @{}
Accept pipeline input: False
Accept wildcard characters: False
```

### -PluginConfiguration
A hashtable of configuration options used by the various plugins (modules) that are installed in PoshBot.
Each key in the hashtable must be the name of a plugin.
The value of that hashtable item will be another hashtable
with each key matching a parameter name in one or more commands of that module.
A plugin command can specifiy that a
parameter gets its value from this configuration by applying the custom attribute \[PoshBot.FromConfig()\] on
the parameter.

The function below is stating that the parameter $MyParam will get its value from the plugin configuration.
The user
running this command in PoshBot does not need to specify this parameter.
PoshBot will dynamically resolve and apply
the matching value from the plugin configuration when the command is executed.

function Get-Foo {
    \[cmdletbinding()\]
    param(
        \[PoshBot.FromConfig()\]
        \[parameter(mandatory)\]
        \[string\]$MyParam
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

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 14
Default value: @{}
Accept pipeline input: False
Accept wildcard characters: False
```

### -BotAdmins
An array of chat handles that will be granted admin rights in PoshBot.
Any user in this array will have full rights in PoshBot.
At startup,
PoshBot will resolve these handles into IDs given by the chat network.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 15
Default value: @()
Accept pipeline input: False
Accept wildcard characters: False
```

### -CommandPrefix
The prefix (single character) that must be specified in front of a command in order for PoshBot to recognize the chat message as a bot command.

!get-foo --value bar

```yaml
Type: Char
Parameter Sets: (All)
Aliases:

Required: False
Position: 16
Default value: !
Accept pipeline input: False
Accept wildcard characters: False
```

### -AlternateCommandPrefixes
Some users may want to specify alternate prefixes when calling bot comamnds.
Use this parameter to specify an array of words that PoshBot
will also check when parsing a chat message.

bender get-foo --value bar

hal open-doors --type pod

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 17
Default value: @('poshbot')
Accept pipeline input: False
Accept wildcard characters: False
```

### -AlternateCommandPrefixSeperators
An array of characters that can also ben used when referencing bot commands.

bender, get-foo --value bar

hal; open-doors --type pod

```yaml
Type: Char[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 18
Default value: @(':', ',', ';')
Accept pipeline input: False
Accept wildcard characters: False
```

### -SendCommandResponseToPrivate
A list of fully qualified (\<PluginName\>:\<CommandName\>) plugin commands that will have their responses redirected back to a direct message
channel with the calling user rather than a shared channel.

@(
    demo:get-foo
    network:ping
)

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 19
Default value: @()
Accept pipeline input: False
Accept wildcard characters: False
```

### -MuteUnknownCommand
Instead of PoshBot returning a warning message when it is unable to find a command, use this to parameter to tell PoshBot to return nothing.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 20
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -AddCommandReactions
Add reactions to a chat message indicating the command is being executed, has succeeded, or failed.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 21
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### -ApprovalExpireMinutes
The amount of time (minutes) that a command the requires approval will be pending until it expires.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 22
Default value: 30
Accept pipeline input: False
Accept wildcard characters: False
```

### -DisallowDMs
Disallow DMs (direct messages) with the bot.
If a user tries to DM the bot it will be ignored.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -FormatEnumerationLimitOverride
Set $FormatEnumerationLimit to this. 
Defaults to unlimited (-1)

Determines how many enumerated items are included in a display.
This variable does not affect the underlying objects; just the display.
When the value of $FormatEnumerationLimit is less than the number of enumerated items, PowerShell adds an ellipsis (...) to indicate items not shown.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 23
Default value: -1
Accept pipeline input: False
Accept wildcard characters: False
```

### -ApprovalCommandConfigurations
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

```yaml
Type: Hashtable[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 24
Default value: @()
Accept pipeline input: False
Accept wildcard characters: False
```

### -ChannelRules
Array of channels rules that control what plugin commands are allowed in a channel.
Wildcards are supported.
Channel names that match against this list will be allowed to have Poshbot commands executed in them.

Internally this uses the \`-like\` comparison operator, not \`-match\`.
Regexes are not allowed.

For best results, list channels and commands from most specific to least specific.
PoshBot will
evaluate the first match found.

Note that the bot will still receive messages from all channels it is a member of.
These message MAY
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

```yaml
Type: Hashtable[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 25
Default value: @()
Accept pipeline input: False
Accept wildcard characters: False
```

### -PreReceiveMiddlewareHooks
Array of middleware scriptblocks that will run before PoshBot "receives" the message from the backend implementation.
This middleware will receive the original message sent from the chat network and have a chance to modify, analyze, and optionally drop the message before PoshBot continues processing it.

```yaml
Type: MiddlewareHook[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 26
Default value: @()
Accept pipeline input: False
Accept wildcard characters: False
```

### -PostReceiveMiddlewareHooks
Array of middleware scriptblocks that will run after a message is "received" from the backend implementation.
This middleware runs after messages have been parsed and matched with a registered command in PoshBot.

```yaml
Type: MiddlewareHook[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 27
Default value: @()
Accept pipeline input: False
Accept wildcard characters: False
```

### -PreExecuteMiddlewareHooks
Array of middleware scriptblocks that will run before a command is executed.
This middleware is a good spot to run extra authentication or validation processes before commands are executed.

```yaml
Type: MiddlewareHook[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 28
Default value: @()
Accept pipeline input: False
Accept wildcard characters: False
```

### -PostExecuteMiddlewareHooks
Array of middleware scriptblocks that will run after PoshBot commands have been executed.
This middleware is a good spot for custom logging solutions to write command history to a custom location.

```yaml
Type: MiddlewareHook[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 29
Default value: @()
Accept pipeline input: False
Accept wildcard characters: False
```

### -PreResponseMiddlewareHooks
Array of middleware scriptblocks that will run before command responses are sent to the backend implementation.
This middleware is a good spot for modifying or sanitizing responses before they are sent to the chat network.

```yaml
Type: MiddlewareHook[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 30
Default value: @()
Accept pipeline input: False
Accept wildcard characters: False
```

### -PostResponseMiddlewareHooks
Array of middleware scriptblocks that will run after command responses have been sent to the backend implementation.
This middleware runs after all processing is complete for a command and is a good spot for additional custom logging.

```yaml
Type: MiddlewareHook[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 31
Default value: @()
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### BotConfiguration
## NOTES

## RELATED LINKS

[Get-PoshBotConfiguration]()

[Save-PoshBotConfiguration]()

[New-PoshBotInstance]()

[Start-PoshBot]()

