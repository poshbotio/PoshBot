---
external help file: PoshBot-help.xml
Module Name: PoshBot
online version:
schema: 2.0.0
---

# New-PoshBotDiscordBackend

## SYNOPSIS
Create a new instance of a Discord backend

## SYNTAX

```
New-PoshBotDiscordBackend [-Configuration] <Hashtable[]> [<CommonParameters>]
```

## DESCRIPTION
Create a new instance of a Discord backend

## EXAMPLES

### EXAMPLE 1
```
$backendConfig = @{
```

Name = 'DiscordBackend'
    Token = '\<DISCORD-BOT-TOKEN-TOKEN\>'
    ClientId = '\<DISCORD-CLIENT-ID\>'
    GuildId = '\<DISCORD-GUILD-ID\>'
}
PS C:\\\> $backend = New-PoshBotDiscordBackend -Configuration $backendConfig

Create a Discord backend using the specified connection information.

## PARAMETERS

### -Configuration
The hashtable containing backend-specific properties on how to create the Discord backend instance.

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

### DiscordBackend
## NOTES

## RELATED LINKS
