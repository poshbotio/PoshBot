---
external help file: PoshBot-help.xml
Module Name: poshbot
online version:
schema: 2.0.0
---

# Get-PoshBotStatefulData

## SYNOPSIS
Get stateful data previously exported from a PoshBot command

## SYNTAX

```
Get-PoshBotStatefulData [[-Name] <String>] [-ValueOnly] [[-Scope] <String>] [<CommonParameters>]
```

## DESCRIPTION
Get stateful data previously exported from a PoshBot command

Reads data from the PoshBot ConfigurationDirectory.

## EXAMPLES

### EXAMPLE 1
```
$ModuleData = Get-PoshBotStatefulData
```

Get all stateful data for the PoshBot plugin this runs from

### EXAMPLE 2
```
$Something = Get-PoshBotStatefulData -Name 'Something' -ValueOnly -Scope Global
```

Set $Something to the value of the 'Something' property from Poshbot's global stateful data

## PARAMETERS

### -Name
If specified, retrieve only this property from the stateful data

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: *
Accept pipeline input: False
Accept wildcard characters: False
```

### -ValueOnly
If specified, return only the value of the specified property Name

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

### -Scope
Get stateful data from this scope:
    Module: Data scoped to this plugin
    Global: Data available to any Poshbot plugin

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: Module
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

[Set-PoshBotStatefulData]()

[Remove-PoshBotStatefulData]()

[Start-PoshBot]()

