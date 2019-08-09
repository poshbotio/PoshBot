---
external help file: PoshBot-help.xml
Module Name: poshbot
online version:
schema: 2.0.0
---

# Set-PoshBotStatefulData

## SYNOPSIS
Save stateful data to use in another PoshBot command

## SYNTAX

```
Set-PoshBotStatefulData [-Name] <String> [-Value] <Object[]> [[-Scope] <String>] [[-Depth] <Int32>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Save stateful data to use in another PoshBot command

Stores data in clixml format, in the PoshBot ConfigurationDirectory.

If \<Name\> property exists in current stateful data file, it is overwritten

## EXAMPLES

### EXAMPLE 1
```
Set-PoshBotStatefulData -Name 'ToUse' -Value 'Later'
```

Adds a 'ToUse' property to the stateful data for the PoshBot plugin you are currently running this from.

### EXAMPLE 2
```
$Anything | Set-PoshBotStatefulData -Name 'Something' -Scope Global
```

Adds a 'Something' property to PoshBot's global stateful data, with the value of $Anything

## PARAMETERS

### -Name
Property to add to the stateful data file

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

### -Value
Value to set for the Name property in the stateful data file

```yaml
Type: Object[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Scope
Sets the scope of stateful data to set:
    Module: Allow only this plugin to access the stateful data you save
    Global: Allow any plugin to access the stateful data you save

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
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
Position: 4
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

[Remove-PoshBotStatefulData]()

[Start-PoshBot]()

