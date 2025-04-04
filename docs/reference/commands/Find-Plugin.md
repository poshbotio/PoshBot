---
external help file: Builtin-help.xml
Module Name: Builtin
online version:
schema: 2.0.0
---

# Find-Plugin

## SYNOPSIS
Find available PoshBot plugins.
Only plugins (PowerShell modules) with the 'PoshBot' tag are returned.

## SYNTAX

```
Find-Plugin -Bot <Object> [[-Name] <String>] [[-Repository] <String>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
{{ Fill in the Description }}

## EXAMPLES

### EXAMPLE 1
```
!find-plugin
```

Find all plugins with the 'PoshBot' tag.

### EXAMPLE 2
```
!find-plugin --name 'xkcd'
```

Find all plugins matching '*xkcd*'

### EXAMPLE 3
```
!find-plugin --name 'itsm' --repository 'internalps'
```

Find all plugins matching '*itsm*' in the 'internalps' repository.

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
The name of the plugin (PowerShell module) to find.
The module in the repository MUST have a 'PoshBot' tag.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Repository
The name of the PowerShell repository to search in.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: PSGallery
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
