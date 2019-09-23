---
external help file: PoshBot-help.xml
Module Name: poshbot
online version:
schema: 2.0.0
---

# Stop-Poshbot

## SYNOPSIS
Stop a currently running PoshBot instance that is running as a background job.

## SYNTAX

```
Stop-Poshbot [-Id] <Int32[]> [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
PoshBot can be run in the background with PowerShell jobs.
This function stops
a currently running PoshBot instance.

## EXAMPLES

### EXAMPLE 1
```
Stop-PoshBot -Id 101
```

Stop the bot instance with Id 101.

### EXAMPLE 2
```
Get-PoshBot | Stop-PoshBot
```

Gets all running PoshBot instances and stops them.

## PARAMETERS

### -Id
The job Id of the bot to stop.

```yaml
Type: Int32[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Force
Stop PoshBot instance without prompt

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

### System.Int32
## OUTPUTS

## NOTES

## RELATED LINKS

[Get-PoshBot]()

[Start-PoshBot]()

