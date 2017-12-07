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

```
Get-CommandHelp -Bot <Object> [[-Filter] <String>] [-Detailed] [-Type <String>]
```

## DESCRIPTION
{{Fill in the Description}}

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
!help --filter new-group
```

Get help on the 'New-Group' command.

### -------------------------- EXAMPLE 2 --------------------------
```
!help new-group --detailed
```

Get detailed help on the 'New-group' command

### -------------------------- EXAMPLE 3 --------------------------
```
!help --type regex
```

List all commands with the \[regex\] trigger type.

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
Parameter Sets: (All)
Aliases: 

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

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

