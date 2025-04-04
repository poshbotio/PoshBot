---
external help file: Builtin-help.xml
Module Name: Builtin
online version:
schema: 2.0.0
---

# Get-CommandHelp

## SYNOPSIS
Show details and help information about bot commands.

## SYNTAX

### Detailed (Default)
```
Get-CommandHelp -Bot <Object> [[-Filter] <String>] [-Detailed] [-Type <String>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### Examples
```
Get-CommandHelp -Bot <Object> [[-Filter] <String>] [-Examples] [-Type <String>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### Full
```
Get-CommandHelp -Bot <Object> [[-Filter] <String>] [-Full] [-Type <String>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
{{ Fill in the Description }}

## EXAMPLES

### EXAMPLE 1
```
!help --filter new-group
```

Get help on the 'New-Group' command.

### EXAMPLE 2
```
!help new-group --detailed
```

Get detailed help on the 'New-group' command

### EXAMPLE 3
```
!help --type regex
```

List all commands with the \[regex\] trigger type.

### EXAMPLE 4
```
!help commandx -Full
```

Display full help for commandx

### EXAMPLE 5
```
!help commandx -Examples
```

Display examples for commandx

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

### -Filter
The text to filter available commands and plugins on.

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

### -Detailed
Show more detailed help information for the command.

```yaml
Type: SwitchParameter
Parameter Sets: Detailed
Aliases: d

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Examples
Include command name, synopsis, and examples.

```yaml
Type: SwitchParameter
Parameter Sets: Examples
Aliases: e

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Full
Displays the entire help topic, including parameter descriptions and attributes, examples, input and output object types, and additional notes.

```yaml
Type: SwitchParameter
Parameter Sets: Full
Aliases: f

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Type
Only return commands of specified type.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: *
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
