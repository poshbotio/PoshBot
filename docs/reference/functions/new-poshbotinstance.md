---
external help file: PoshBot-help.xml
online version: 
schema: 2.0.0
---

# New-PoshBotInstance

## SYNOPSIS
Creates a new instance of PoshBot

## SYNTAX

### path (Default)
```
New-PoshBotInstance [-Path <String[]>] -Backend <Backend>
```

### config
```
New-PoshBotInstance -Configuration <BotConfiguration[]> -Backend <Backend>
```

## DESCRIPTION
Creates a new instance of PoshBot from an existing configuration (.psd1) file or a configuration object.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
New-PoshBotInstance -Path 'C:\Users\joeuser\.poshbot\Cherry2000.psd1' -Backend $backend
```

Name          : Cherry2000
Backend       : SlackBackend
Storage       : StorageProvider
PluginManager : PluginManager
RoleManager   : RoleManager
Executor      : CommandExecutor
MessageQueue  : {}
Configuration : BotConfiguration

Create a new PoshBot instance from configuration file \[C:\Users\joeuser\.poshbot\Cherry2000.psd1\] and Slack backend object \[$backend\].

### -------------------------- EXAMPLE 2 --------------------------
```
$botConfig = Get-PoshBotConfiguration -Path (Join-Path -Path $env:USERPROFILE -ChildPath '.poshbot\Cherry2000.psd1')
```

PS C:\\\> $backend = New-PoshBotSlackBackend -Configuration $botConfig.BackendConfiguration
PS C:\\\> $myBot = $botConfig | New-PoshBotInstance -Backend $backend
PS C:\\\> $myBot | Format-List

Name          : Cherry2000
Backend       : SlackBackend
Storage       : StorageProvider
PluginManager : PluginManager
RoleManager   : RoleManager
Executor      : CommandExecutor
MessageQueue  : {}
Configuration : BotConfiguration

Gets a bot configuration from the filesytem, creates a chat backend object, and then creates a new bot instance.

### -------------------------- EXAMPLE 3 --------------------------
```
$botConfig = Get-PoshBotConfiguration -Path (Join-Path -Path $env:USERPROFILE -ChildPath '.poshbot\Cherry2000.psd1')
```

PS C:\\\> $backend = $botConfig | New-PoshBotSlackBackend
PS C:\\\> $myBotJob = $botConfig | New-PoshBotInstance -Backend $backend | Start-PoshBot -AsJob -PassThru

Gets a bot configuration, creates a Slack backend from it, then creates a new PoshBot instance and starts it as a background job.

## PARAMETERS

### -Path
The path to a PowerShell data (.psd1) file to create a new instance from.

```yaml
Type: String[]
Parameter Sets: path
Aliases: 

Required: False
Position: Named
Default value: (Join-Path -Path (Join-Path -Path $env:USERPROFILE -ChildPath '.poshbot') -ChildPath 'PoshBot.psd1')
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Configuration
The bot configuration object to create a new instance from.

```yaml
Type: BotConfiguration[]
Parameter Sets: config
Aliases: 

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Backend
The backend object that hosts logic for receiving and sending messages to a chat network.

```yaml
Type: Backend
Parameter Sets: (All)
Aliases: 

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

### String

### BotConfiguration

## OUTPUTS

### Bot

## NOTES

## RELATED LINKS

[Get-PoshBotConfiguration]()

[New-PoshBotSlackBackend]()

[Start-PoshBot]()

