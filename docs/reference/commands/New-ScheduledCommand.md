---
external help file: Builtin-help.xml
Module Name: Builtin
online version:
schema: 2.0.0
---

# New-ScheduledCommand

## SYNOPSIS
Create a new scheduled command.

## SYNTAX

### repeat (Default)
```
New-ScheduledCommand -Bot <Object> [-Command] <String> [-Value] <Int32> [-Interval] <String>
 [-StartAfter <String>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### once
```
New-ScheduledCommand -Bot <Object> [-Command] <String> -StartAfter <String> [-Once]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
{{ Fill in the Description }}

## EXAMPLES

### EXAMPLE 1
```
!new-scheduledcommand --command 'status' --interval hours --value 4
```

Execute the \[status\] command every 4 hours.

### EXAMPLE 2
```
!new-scheduledcommand --command !myplugin:motd' --interval days --value 1 --startafter '8:00am'
```

Execute the command \[myplugin:motd\] every day starting at 8:00am.

### EXAMPLE 3
```
!new-scheduledcommand --command "!myplugin:restart-server --computername frodo --startafter '2016/07/04 6:00pm'" --once
```

Execute the command \[restart-server\] on computername \[frodo\] at 6:00pm on 2016/07/04.

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

### -Command
The command string to schedule.
This will be in the form of '!foo --bar baz' just like you would
type interactively.

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
Parameter Sets: repeat
Aliases:

Required: True
Position: 2
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -Interval
The interval in which to schedule the command.
The valid values are 'days', 'hours', 'minutes', and 'seconds'.

```yaml
Type: String
Parameter Sets: repeat
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
Parameter Sets: repeat
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: once
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Once
Execute the scheduled command once and then remove the schedule.
This parameter is not valid with the Interval and Value parameters.

```yaml
Type: SwitchParameter
Parameter Sets: once
Aliases:

Required: True
Position: Named
Default value: False
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
