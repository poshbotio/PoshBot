---
external help file: PoshBot-help.xml
Module Name: poshbot
online version:
schema: 2.0.0
---

# Save-PoshBotConfiguration

## SYNOPSIS
Saves a PoshBot configuration object to the filesystem in the form of a PowerShell data (.psd1) file.

## SYNTAX

```
Save-PoshBotConfiguration [-InputObject] <BotConfiguration> [[-Path] <String>] [-Force] [-PassThru] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
PoshBot configurations can be stored on the filesytem in PowerShell data (.psd1) files.
This function will save a previously created configuration object to the filesystem.

## EXAMPLES

### EXAMPLE 1
```
Save-PoshBotConfiguration -InputObject $botConfig
```

Saves the PoshBot configuration.
If now -Path is specified, the configuration will be saved to $env:USERPROFILE\.poshbot\PoshBot.psd1.

### EXAMPLE 2
```
$botConfig | Save-PoshBotConfig -Path c:\mybot\mybot.psd1
```

Saves the PoshBot configuration to \[c:\mybot\mybot.psd1\].

### EXAMPLE 3
```
$configFile = $botConfig | Save-PoshBotConfig -Path c:\mybot\mybot.psd1 -Force -PassThru
```

Saves the PoshBot configuration to \[c:\mybot\mybot.psd1\] and Overwrites existing file.
The new file will be returned.

## PARAMETERS

### -InputObject
The bot configuration object to save to the filesystem.

```yaml
Type: BotConfiguration
Parameter Sets: (All)
Aliases: Configuration

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Path
The path to a PowerShell data (.psd1) file to save the configuration to.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: (Join-Path -Path $script:defaultPoshBotDir -ChildPath 'PoshBot.psd1')
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
Overwrites an existing configuration file.

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

### -PassThru
Returns the configuration file path.

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

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### BotConfiguration
## OUTPUTS

### System.IO.FileInfo
## NOTES

## RELATED LINKS

[Get-PoshBotConfiguration]()

[Start-PoshBot]()

