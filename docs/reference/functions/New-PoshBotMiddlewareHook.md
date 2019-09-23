---
external help file: PoshBot-help.xml
Module Name: poshbot
online version:
schema: 2.0.0
---

# New-PoshBotMiddlewareHook

## SYNOPSIS
Creates a PoshBot middleware hook object.

## SYNTAX

```
New-PoshBotMiddlewareHook [-Name] <String> [-Path] <String> [<CommonParameters>]
```

## DESCRIPTION
PoshBot can execute custom scripts during various stages of the command processing lifecycle.
These scripts
are defined using New-PoshBotMiddlewareHook and added to the bot configuration object under the MiddlewareConfiguration section.
Hooks are added to the PreReceive, PostReceive, PreExecute, PostExecute, PreResponse, and PostResponse properties.
Middleware gets executed in the order in which it is added under each property.

## EXAMPLES

### EXAMPLE 1
```
$userDropHook = New-PoshBotMiddlewareHook -Name 'dropuser' -Path 'c:/poshbot/middleware/dropuser.ps1'
```

PS C:\\\> $config.MiddlewareConfiguration.Add($userDropHook, 'PreReceive')

Creates a middleware hook called 'dropuser' and adds it to the 'PreReceive' middleware lifecycle stage.

## PARAMETERS

### -Name
The name of the middleware hook.
Must be unique in each middleware lifecycle stage.

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

### -Path
The file path the the PowerShell script to execute as a middleware hook.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### MiddlewareHook
## NOTES

## RELATED LINKS
