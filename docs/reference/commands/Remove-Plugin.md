---
external help file: Builtin-help.xml
online version: 
schema: 2.0.0
---

# Remove-Plugin

## SYNOPSIS
Removes a currently loaded plugin.

## SYNTAX

```
Remove-Plugin -Bot <Object> [-Name] <String> [[-Version] <String>]
```

## DESCRIPTION
{{Fill in the Description}}

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
!remove-plugin nameit
```

Remove the \[NameIt\] plugin.

### -------------------------- EXAMPLE 2 --------------------------
```
!remove-plugin --name PoshBot.XKCD --version 1.0.0
```

Remove version \[1.0.0\] of the \[PoshBot.XKCD\] module.

## PARAMETERS

### -Bot
{{Fill Bot Description}}

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
The name of the plugin to remove.

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
The specific version of the plugin to remove.

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

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

