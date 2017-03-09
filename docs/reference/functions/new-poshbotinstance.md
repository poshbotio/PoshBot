
# New-PoshBotInstance

## SYNOPSIS

Creates a new instance of PoshBot

## DESCRIPTION

Creates a new instance of PoshBot from an existing configuration (.psd1) file or a configuration object.

## PARAMETERS

### Configuration

The bot configuration object to create a new instance from.

### Path

The path to a PowerShell data (.psd1) file to create a new instance from.

### Backend

The backend object that hosts logic for receiving and sending messages to a chat network.

## EXAMPLES

### EXAMPLE 1

Create a new PoshBot instance from configuration file [C:\Users\joeuser\.poshbot\Cherry2000.psd1] and Slack backend object [$backend].

```powershell
PS C:\> New-PoshBotInstance -Path 'C:\Users\joeuser\.poshbot\Cherry2000.psd1' -Backend $backend

Name          : Cherry2000
Backend       : SlackBackend
Storage       : StorageProvider
PluginManager : PluginManager
RoleManager   : RoleManager
Executor      : CommandExecutor
MessageQueue  : {}
Configuration : BotConfiguration
```

### EXAMPLE 2

Gets a bot configuration from the filesytem, creates a chat backend object, and then creates a new bot instance.

```powershell
PS C:\> $botConfig = Get-PoshBotConfiguration -Path (Join-Path -Path $env:USERPROFILE -ChildPath '.poshbot\Cherry2000.psd1')
PS C:\> $backend = New-PoshBotSlackBackend -Configuration $botConfig.BackendConfiguration
PS C:\> $myBot = $botConfig | New-PoshBotInstance -Backend $backend
PS C:\> $myBot | Format-List

Name          : Cherry2000
Backend       : SlackBackend
Storage       : StorageProvider
PluginManager : PluginManager
RoleManager   : RoleManager
Executor      : CommandExecutor
MessageQueue  : {}
Configuration : BotConfiguration
```

### EXAMPLE 3

Gets a bot configuration, creates a Slack backend from it, then creates a new PoshBot instance and starts it as a background job.

```powershell
PS C:\> $botConfig = Get-PoshBotConfiguration -Path (Join-Path -Path $env:USERPROFILE -ChildPath '.poshbot\Cherry2000.psd1')
PS C:\> $backend = $botConfig | New-PoshBotSlackBackend
PS C:\> $myBotJob = $botConfig | New-PoshBotInstance -Backend $backend | Start-PoshBot -AsJob -PassThru
```

## INPUTS

String

## INPUTS

BotConfiguration

## OUTPUTS

Bot
