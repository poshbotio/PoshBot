---
external help file: Builtin-help.xml
Module Name: Builtin
online version:
schema: 2.0.0
---

# Install-Plugin

## SYNOPSIS
Install a new plugin.

## SYNTAX

```
Install-Plugin -Bot <Object> [-Name] <String> [[-Version] <String>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
{{ Fill in the Description }}

## EXAMPLES

### EXAMPLE 1
```
!install-plugin nameit
```

Install the \[NameIt\] plugin.

### EXAMPLE 2
```
!install-plugin --name PoshBot.XKCD --version 1.0.0
```

Install version \[1.0.0\] of the \[PoshBot.XKCD\] plugin.

## PARAMETERS

### -Bot
{{ Fill Bot Description }}

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name
The name of the PoshBot plugin (PowerShell module) to install.
The plugin must already exist in $env:PSModulePath or be present
in on of the configured plugin repositories (PowerShell repositories).
If not already installed, PoshBot will install the module from the repository.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Version
The specific version of the plugin to install.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProgressAction
{{ Fill ProgressAction Description }}

```yaml
Type: ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
