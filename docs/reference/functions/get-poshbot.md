---
external help file: PoshBot-help.xml
Module Name: poshbot
online version:
schema: 2.0.0
---

# Get-PoshBot

## SYNOPSIS
Gets any currently running instances of PoshBot that are running as background jobs.

## SYNTAX

```
Get-PoshBot [[-Id] <Int32[]>] [<CommonParameters>]
```

## DESCRIPTION
PoshBot can be run in the background with PowerShell jobs.
This function returns
any currently running PoshBot instances.

## EXAMPLES

### EXAMPLE 1
```
Get-PoshBot
```

Id         : 5
Name       : PoshBot_3ddfc676406d40fca149019d935f065d
State      : Running
InstanceId : 3ddfc676406d40fca149019d935f065d
Config     : BotConfiguration

### EXAMPLE 2
```
Get-PoshBot -Id 100
```

Id         : 100
Name       : PoshBot_eab96f2ad147489b9f90e110e02ad805
State      : Running
InstanceId : eab96f2ad147489b9f90e110e02ad805
Config     : BotConfiguration

Gets the PoshBot job instance with ID 100.

## PARAMETERS

### -Id
One or more job IDs to retrieve.

```yaml
Type: Int32[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: @()
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.Int32
## OUTPUTS

### PSCustomObject
## NOTES

## RELATED LINKS

[Start-PoshBot]()

[Stop-PoshBot]()

