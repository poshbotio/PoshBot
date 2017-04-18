---
external help file: PoshBot-help.xml
online version: 
schema: 2.0.0
---

# Get-PoshBotConfiguration

## SYNOPSIS
Gets a PoshBot configuration from a file.

## SYNTAX

```
Get-PoshBotConfiguration [[-Path] <String[]>]
```

## DESCRIPTION
PoshBot configurations can be stored on the filesytem in PowerShell data (.psd1) files.
This functions will load that file and return a \[BotConfiguration\] object.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-PoshBotConfiguration -Path C:\Users\joeuser\.poshbot\Cherry2000.psd1
```

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

Gets the bot configuration located at \[C:\Users\joeuser\.poshbot\Cherry2000.psd1\].

### -------------------------- EXAMPLE 2 --------------------------
```
$botConfig = 'C:\Users\joeuser\.poshbot\Cherry2000.psd1' | Get-PoshBotConfiguration
```

Gets the bot configuration located at \[C:\Users\brand\.poshbot\Cherry2000.psd1\].

## PARAMETERS

### -Path
One or more paths to a PoshBot configuration file.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: 

Required: False
Position: 1
Default value: (Join-Path -Path (Join-Path -Path $env:USERPROFILE -ChildPath '.poshbot') -ChildPath 'PoshBot.psd1')
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

## INPUTS

### String

## OUTPUTS

### BotConfiguration

## NOTES

## RELATED LINKS

[New-PoshBotConfiguration]()

[Start-PoshBot]()

