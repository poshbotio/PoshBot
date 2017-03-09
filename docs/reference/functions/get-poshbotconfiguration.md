
# Get-PoshBotConfiguration

## SYNOPSIS

Gets a PoshBot configuration from a file.

## DESCRIPTION

PoshBot configurations can be stored on the filesytem in PowerShell data (.psd1) files.
This functions will load that file and return a [BotConfiguration] object.

## PARAMETERS

### Path

One or more paths to a PoshBot configuration file.

## EXAMPLES

### EXAMPLE 1

Gets the bot configuration located at [C:\Users\joeuser\.poshbot\Cherry2000.psd1].

```powershell
PS C:\> Get-PoshBotConfiguration -Path C:\Users\joeuser\.poshbot\Cherry2000.psd1

Name                             : Cherry2000
ConfigurationDirectory           : C:\Users\joeuser\.poshbot
LogDirectory                     : C:\Users\joeuser\.poshbot\Logs
PluginDirectory                  : C:\Users\joeuser\.poshbot
PluginRepository                 : {PSGallery}
ModuleManifestsToLoad            : {}
LogLevel                         : Debug
BackendConfiguration             : {Token, Name}
PluginConfiguration              : {}
BotAdmins                        : {joeuser}
CommandPrefix                    : !
AlternateCommandPrefixes         : {bender, hal}
AlternateCommandPrefixSeperators : {:, ,, ;}
SendCommandResponseToPrivate     : {}
MuteUnknownCommand               : False
```

### EXAMPLE 2

Gets the bot configuration located at [C:\Users\brand\.poshbot\Cherry2000.psd1].

```powershell
PS C:\> $botConfig = 'C:\Users\joeuser\.poshbot\Cherry2000.psd1' | Get-PoshBotConfiguration
```

## INPUTS

String

## OUTPUTS

BotConfiguration
