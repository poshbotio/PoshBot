---
external help file: PoshBot-help.xml
Module Name: poshbot
online version:
schema: 2.0.0
---

# New-PoshBotSlackBackend

## SYNOPSIS
Create a new instance of a Slack backend

## SYNTAX

```
New-PoshBotSlackBackend [-Configuration] <Hashtable[]> [<CommonParameters>]
```

## DESCRIPTION
Create a new instance of a Slack backend

## EXAMPLES

### EXAMPLE 1
```
$backendConfig = @{Name = 'SlackBackend'; Token = '<SLACK-API-TOKEN>'}
```

PS C:\\\> $backend = New-PoshBotSlackBackend -Configuration $backendConfig

Create a Slack backend using the specified API token

## PARAMETERS

### -Configuration
The hashtable containing backend-specific properties on how to create the Slack backend instance.

```yaml
Type: Hashtable[]
Parameter Sets: (All)
Aliases: BackendConfiguration

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### Hashtable
## OUTPUTS

### SlackBackend
## NOTES

## RELATED LINKS
