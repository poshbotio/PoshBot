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
New-PoshBotSlackBackend [-Configuration] <Hashtable[]> [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Create a new instance of a Slack backend

## EXAMPLES

### EXAMPLE 1
```
$backendConfig = @{
    Name = 'SlackBackend'
    BotToken = '<BOT-TOKEN>' | ConvertTo-SecureString -AsPlainText -Force
    WebSocketToken = '<WEBSOCKET-TOKEN>' | ConvertTo-SecureString -AsPlainText -Force
}
PS C:\> $$backend = New-PoshBotSlackBackend -Configuration $backendConfig
```

Create a Slack backend using the specified tokens.

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

### Hashtable
## OUTPUTS

### SlackBackend
## NOTES

## RELATED LINKS
