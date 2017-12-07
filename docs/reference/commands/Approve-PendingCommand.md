---
external help file: Builtin-help.xml
Module Name: Builtin
online version: 
schema: 2.0.0
---

# Approve-PendingCommand

## SYNOPSIS
Approved a command for execution.

## SYNTAX

```
Approve-PendingCommand -Bot <Object> [-Id] <String>
```

## DESCRIPTION
{{Fill in the Description}}

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
!approve -id f087f1fd
```

Approve the command with ID f087f1fd.
The command will immediately be released and executed.

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

### -Id
The command exeution context ID of a command awaiting approval.

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

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

