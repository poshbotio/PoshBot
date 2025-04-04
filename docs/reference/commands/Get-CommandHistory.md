---
external help file: Builtin-help.xml
Module Name: Builtin
online version:
schema: 2.0.0
---

# Get-CommandHistory

## SYNOPSIS
Get the recent execution history of a command

## SYNTAX

### all (Default)
```
Get-CommandHistory -Bot <Object> [[-Count] <Int32>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### name
```
Get-CommandHistory -Bot <Object> [[-Name] <String>] [[-Count] <Int32>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

### id
```
Get-CommandHistory -Bot <Object> [[-Id] <String>] [[-Count] <Int32>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
{{ Fill in the Description }}

## EXAMPLES

### EXAMPLE 1
```
!get-commandhistory
```

Get all recent command history.

### EXAMPLE 2
```
!get-commandhistory --name 'status' --count 2
```

Get the last 2 execution history entries for the \[status\] command.

### EXAMPLE 3
```
!get-commandhistory --id 5d337f17-bdc7-4f51-af0f-2629ac8224ce
```

Get details about command exeuction Id \[5d337f17-bdc7-4f51-af0f-2629ac8224ce\].

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
The command name to get history for.

```yaml
Type: String
Parameter Sets: name
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Id
Theh Id of the command execution to get details for.

```yaml
Type: String
Parameter Sets: id
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Count
The number of most recent history items to retrieve.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: 20
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
