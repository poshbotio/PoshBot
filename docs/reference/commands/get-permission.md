---
external help file: Builtin-help.xml
online version: 
schema: 2.0.0
---

# Get-Permission

## SYNOPSIS
Show details about bot permissions.

## SYNTAX

```
Get-Permission -Bot <Object> [[-Name] <String>]
```

## DESCRIPTION
{{Fill in the Description}}

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
!get-permission
```

Get a list of all permissions.

### -------------------------- EXAMPLE 2 --------------------------
```
!get-permission --name builtin:manage-groups
```

Get details about the \[builtin:manage-groups\] permission.

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
The name of the permission to get.

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

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

