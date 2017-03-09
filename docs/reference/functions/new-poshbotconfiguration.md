
# New-PoshBotConfiguration

## SYNOPSIS

Creates a new PoshBot configuration object.

## DESCRIPTION

Creates a new PoshBot configuration object.

## PARAMETERS

### Name

The name the bot instance will be known as.

### LogDirectory

The log directory logs will be written to.

### PluginDirectory

The directory PoshBot will look for PowerShell modules.
This path will be prepended to your $env:PSModulePath.

### PluginRepository

One or more PowerShell repositories to look in when installing new plugins (modules).
These will be the repository name(s) as found in Get-PSRepository.

### ModuleManifestsToLoad

One or more paths to module manifest (.psd1) files.
These modules will be automatically loaded when PoshBot starts.

### LogLevel

The level of logging that PoshBot will do.

### BackendConfiguration

A hashtable of configuration options required by the backend chat network implementation.

### PluginConfiguration

A hashtable of configuration options used by the various plugins (modules) that are installed in PoshBot.
Each key in the hashtable must be the name of a plugin.
The value of that hashtable item will be another hashtable with each key matching a parameter name in one or more commands of that module.
A plugin command can specifiy that a parameter gets its value from this configuration by applying the custom attribute [PoshBot.FromConfig()] on the parameter.

The function below is stating that the parameter $MyParam will get its value from the plugin configuration.
The user running this command in PoshBot does not need to specify this parameter.
PoshBot will dynamically resolve and apply the matching value from the plugin configuration when the command is executed.

```powershell
function Get-Foo {
    [cmdletbinding()]
    param(
        [PoshBot.FromConfig()]
        [parameter(mandatory)]
        [string]$MyParam
    )

    Write-Output $MyParam
}
```

If the function below was part of the Demo plugin, PoshBot will look in the plugin configuration for a key matching Demo and a child key matching $MyParam.

Example plugin configuration:

```powershell
@{
    Demo = @{
        MyParam = 'bar'
    }
}
```

### BotAdmins

An array of chat handles that will be granted admin rights in PoshBot. Any user in this array will have full rights in PoshBot. At startup,
PoshBot will resolve these handles into IDs given by the chat network.

### CommandPrefix

The prefix (single character) that must be specified in front of a command in order for PoshBot to recognize the chat message as a bot command.

```
!get-foo --value bar
```

### AlternateCommandPrefixes

Some users may want to specify alternate prefixes when calling bot comamnds.
Use this parameter to specify an array of words that PoshBot will also check when parsing a chat message.

```
bender get-foo --value bar
```

```
hal open-doors --type pod
```

### AlternateCommandPrefixSeperators

An array of characters that can also ben used when referencing bot commands.

```
bender, get-foo --value bar
```

```
hal; open-doors --type pod
```

### SendCommandResponseToPrivate

A list of fully qualified (<PluginName>:<CommandName>) plugin commands that will have their responses redirected back to a direct message channel with the calling user rather than a shared channel.

```powershell
@(
    demo:get-foo
    network:ping
)
```

### MuteUnknownCommand

Instead of PoshBot returning a warning message when it is unable to find a command, use this to parameter to tell PoshBot to return nothing.

## EXAMPLES

### EXAMPLE 1

Create a new PoshBot configuration with default values except for the bot name and alternate command prefixes that it will listen for.

```powershell
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
```

### EXAMPLE 2

Create a new PoshBot configuration with a Slack backend.
Slack's backend only requires a bot token to be specified.
Ensure the person with Slack handle 'JoeUser' is a bot admin.

```powershell
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

PS C:\> $myBotConfig | Start-PoshBot -AsJob
```

## OUTPUTS

BotConfiguration
