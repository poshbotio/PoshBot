---
external help file: PoshBot-help.xml
Module Name: poshbot
online version:
schema: 2.0.0
---

# Get-PoshBotConfiguration

## SYNOPSIS
Gets a PoshBot configuration from a file.

## SYNTAX

### Path (Default)
```
Get-PoshBotConfiguration [-Path] <String[]> [<CommonParameters>]
```

### LiteralPath
```
Get-PoshBotConfiguration [-LiteralPath] <String[]> [<CommonParameters>]
```

## DESCRIPTION
PoshBot configurations can be stored on the filesytem in PowerShell data (.psd1) files.
This functions will load that file and return a \[BotConfiguration\] object.

## EXAMPLES

### EXAMPLE 1
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
AddCommandReactions              : True

Gets the bot configuration located at \[C:\Users\joeuser\.poshbot\Cherry2000.psd1\].

### EXAMPLE 2
```
$botConfig = 'C:\Users\joeuser\.poshbot\Cherry2000.psd1' | Get-PoshBotConfiguration
```

Gets the bot configuration located at \[C:\Users\brand\.poshbot\Cherry2000.psd1\].

## PARAMETERS

### -Path
One or more paths to a PoshBot configuration file.

```yaml
Type: String[]
Parameter Sets: Path
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: True
```

### -LiteralPath
Specifies the path(s) to the current location of the file(s).
Unlike the Path parameter, the value of LiteralPath is used exactly as it is typed.
No characters are interpreted as wildcards.
If the path includes escape characters, enclose it in single quotation marks.
Single quotation
marks tell PowerShell not to interpret any characters as escape sequences.

```yaml
Type: String[]
Parameter Sets: LiteralPath
Aliases: PSPath

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### String
## OUTPUTS

### BotConfiguration
## NOTES

## RELATED LINKS

[New-PoshBotConfiguration]()

[Start-PoshBot]()

