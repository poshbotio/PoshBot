---
external help file: PoshBot-help.xml
Module Name: poshbot
online version:
schema: 2.0.0
---

# Remove-PoshBotStatefulData

## SYNOPSIS
Remove existing stateful data

## SYNTAX

```
Remove-PoshBotStatefulData [-Name] <String[]> [[-Scope] <String>] [[-Depth] <Int32>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
Remove existing stateful data

## EXAMPLES

### EXAMPLE 1
```
Remove-PoshBotStatefulData -Name 'ToUse'
```

Removes the 'ToUse' property from stateful data for the PoshBot plugin you are currently running this from.

### EXAMPLE 2
```
Remove-PoshBotStatefulData -Name 'Something' -Scope Global
```

Removes the 'Something' property from PoshBot's global stateful data

## PARAMETERS

### -Name
Property to remove from the stateful data file

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Scope
Sets the scope of stateful data to remove:
    Module: Remove stateful data from the current module's data
    Global: Remove stateful data from the global PoshBot data

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

### -Depth
Specifies how many levels of contained objects are included in the XML representation.
The default value is 2

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: 2
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

## OUTPUTS

## NOTES

## RELATED LINKS

[Get-PoshBotStatefulData]()

[Set-PoshBotStatefulData]()

[Start-PoshBot]()

