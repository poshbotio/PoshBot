---
external help file: Builtin-help.xml
Module Name: Builtin
online version:
schema: 2.0.0
---

# Set-ScheduledCommand

## SYNOPSIS
Modify a scheduled command.

## SYNTAX

```
Set-ScheduledCommand -Bot <Object> [-Id] <String> [-Value] <Int32> [-Interval] <String> [-StartAfter <String>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
{{ Fill in the Description }}

## EXAMPLES

### EXAMPLE 1
```
!set-scheduledcommand --id e26b82cf473647e780041cee00a941de --value 2 --interval days
```

Edit the existing scheduled command with Id \[e26b82cf473647e780041cee00a941de\] and set the
repetition interval to every 2 days.

### EXAMPLE 2
```
!set-scheduledcommand --id ccef0790b94542a685e78b4ec50c8c1e --value 1 --interval hours --startafter '10:00pm'
```

Edit the existing scheduled command with Id \[ccef0790b94542a685e78b4ec50c8c1e\] and set the
repition interval to every hours starting at 10:00pm.

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

### -Id
The Id of the scheduled command to edit.

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
Execute the command after the specified number of intervals (e.g., 2 hours).

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -Interval
{{ Fill Interval Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -StartAfter
Start the scheduled command exeuction after this date/time.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
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
