---
external help file: PoshBot-help.xml
Module Name: poshbot
online version:
schema: 2.0.0
---

# New-PoshBotTeamsBackend

## SYNOPSIS
Create a new instance of a Microsoft Teams backend

## SYNTAX

```
New-PoshBotTeamsBackend [-Configuration] <Hashtable[]> [<CommonParameters>]
```

## DESCRIPTION
Create a new instance of a Microsoft Teams backend

## EXAMPLES

### EXAMPLE 1
```
$backendConfig = @{
```

Name = 'TeamsBackend'
    Credential = \[pscredential\]::new(
        '\<BOT-ID\>',
        ('\<BOT-PASSWORD\>' | ConvertTo-SecureString -AsPlainText -Force)
    )
    ServiceBusNamespace = '\<SERVICEBUS-NAMESPACE\>'
    QueueName           = '\<QUEUE-NAME\>'
    AccessKeyName       = '\<KEY-NAME\>'
    AccessKey           = '\<SECRET\>' | ConvertTo-SecureString -AsPlainText -Force
}
PS C:\\\> $$backend = New-PoshBotTeamsBackend -Configuration $backendConfig

Create a Microsoft Teams backend using the specified Bot Framework credentials and Service Bus information

## PARAMETERS

### -Configuration
The hashtable containing backend-specific properties on how to create the instance.

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

### TeamsBackend
## NOTES

## RELATED LINKS
