
# Configuration

Configuration for PoshBot consists of a number of properties that govern the behavior of the bot.

A default bot configuration can be created by running `New-PoshBotConfiguration`

```powershell
$backendConfig = @{Name = 'SlackBackend'; Token = 'SLACK-API-TOKEN'}
$pbc = New-PoshBotConfiguration -BotAdmins @('<my-slack-handle>') -BackendConfiguration $backendConfig
Save-PoshBotConfiguration -InputObject $pbc -Path .\PoshBotConfig.psd1
Get-Content .\PoshBotConfig.psd1
```

If you look at `.\PoshBotConfig.psd1` it should resemble the following:

```powershell
@{
  PluginRepository = @('PSGallery')
  AlternateCommandPrefixSeperators = @(':',',',';')
  ModuleManifestsToLoad = @()
  LogDirectory = 'C:\Users\brandon\.poshbot'
  Name = 'PoshBot'
  BotAdmins = @('<my-slack-handle>')
  LogLevel = 'Verbose'
  MaxLogSizeMB = 10
  MaxLogsToKeep = 3
  LogCommandHistory = $true
  CommandHistoryMaxLogSizeMB = 10
  CommandHistoryMaxLogsToKeep = 5
  SendCommandResponseToPrivate = @()
  ConfigurationDirectory = 'C:\Users\brandon\.poshbot'
  AddCommandReactions = $True
  PluginDirectory = 'C:\Users\brandon\.poshbot'
  MuteUnknownCommand = $false
  PluginConfiguration = @{

  }
  AlternateCommandPrefixes = @('poshbot')
  CommandPrefix = '!'
  BackendConfiguration = @{
    Token = '<SLACK-API-TOKEN>'
    Name = 'SlackBackend'
  }
  ApprovalConfiguration = @{}
  ChannelRules = @(
    @{
      Channel = '*'
      IncludeCommands = @('*')
      ExcludeCommands = @()
    }
  )
  DisallowDMs = $false
}
```

Provided you have a valid bot token (which you can create in Slack at [https://api.slack.com/bot-users](https://api.slack.com/bot-users)), you can create a new instance of the bot from this configuration and start it by running the following:

```powershell
$pbc = Get-PoshBotConfiguration -Path .\PoshBotConfig.psd1
$backend = New-PoshBotSlackBackend -Configuration $pbc.BackendConfiguration
$bot = New-PoshBotInstance -Configuration $pbc -Backend $backend
$bot.Start()
```

Here is a rundown of the various configuration properties and what they do:

| Property                        | Type        | Description |
|:--------------------------------|:------------|:------------|
Name                              | string      | A name of the bot
ConfigurationDirectory            | string      | The directory to store bot configuration in
LogDirectory                      | string      | The directory to store bot logs in
PluginDirectory                   | string      | The directory to first look for plugins (modules) in
PluginRepository                  | string[]    | The PowerShell repository(s) to look for plugins (modules) in
ModuleManifestsToLoad             | string[]    | Path(s) to module manifests to load at bot startup
AddCommandReactions               | bool        | Add reactions to a chat message indicating the command is being executed, has succeeded, or failed
LogLevel                          | string      | The verbosity of logs
MaxLogSizeMB                      | int         | The maximum log file size in megabytes
MaxLogsToKeep                     | int         | The maximum number of logs to keep before rotating
LogCommandHistory                 | bool        | Log command history to a separate file for convenience
CommandHistoryMaxLogSizeMB        | int         | The maximum log file size for the command history
CommandHistoryMaxLogsToKeep       | int         | The maximum number of logs to keep for command history before rotating
BackendConfiguration              | hashtable   | Hashtable containing configuration settings needed by backend provider
PluginConfiguration               | hashtable   | Hashtable of parameter values to pass to bot commands when appropriate
BotAdmins                         | string[]    | List of chat handles who will granted bot administrator privledges
CommandPrefix                     | char        | Primary prefix to use to determine if messages are bot commands
AlternateCommandPrefixes          | string[]    | Alternate prefix(es) to use to determine if messages are bot commands
AlternateCommandPrefixSeperators  | char[]      | Alternate prefix seperator(s) to use to determine if messages are bot commands
SendCommandResponseToPrivate      | string[]    | Array of fully qualified bot commands to redirect responses to DM channels
MuteUnknownCommand                | bool        | Control whether unknown commands produce warning message back to chat network
ApprovalExpireMinutes             | int         | The amount of time (minutes) that a command the requires approval will be pending until it expires
ApprovalCommandConfigurations     | hashtable[] | Array of hashtables containing command approval configurations
DisallowDMs                       | bool        | Disallow commands in DM channels with PoshBot
ChannelRules                      | hashtable[] | Array of channels rules that control what plugin commands are allowed in a channel

## Storage

PoshBot will save the state of the bot in a location defined by the bot configurations's `ConfigurationDirectory` property (the default location is $env:userprofile\\.poshbot).
Four files will be saved here as well the primary configuration file.

### Groups.psd1

This file holds the list of groups that have been created for securing access to commands.
As groups are created/removed/updated via bot commands, this file will be updated.
When PoshBot starts, this file is loaded so group definitions are not lost between bot restarts.

#### Example groups.psd1

```powershell
@{
  Admin = @{
    Description = 'Bot administrators'
    Users = @('U4KEOSDJ6')
    Roles = @('Admin')
  }
  operators = @{
    Description = 'The operator role'
    Users = @('U6KCNSKU4')
    Roles = @('network-operator')
  }
}
```

### Permissions.psd1

This file holds the list of permissions that have been created for securing access to commands.
As plugins are loaded/unloaded, this file will hold the current set of permissions.
When PoshBot starts, this file is loaded so permission definitions are not lost between bot restarts.

#### Example permissions.psd1

```powershell
@{
  'Builtin:show-help' = @{
    Plugin = 'Builtin'
    Name = 'show-help'
    Description = 'Can display help about commands'
  }
  'Network:test-network' = @{
    Plugin = 'Network'
    Name = 'test-network'
    Description = 'Run commands to test network connectivity'
  }
  'Builtin:manage-plugins' = @{
    Plugin = 'Builtin'
    Name = 'manage-plugins'
    Description = 'Can install/enable/disable plugins'
  }
  'Builtin:manage-roles' = @{
    Plugin = 'Builtin'
    Name = 'manage-roles'
    Description = 'Can create/create/update/delete roles'
  }
  'Demo:dice-master' = @{
    Plugin = 'Demo'
    Name = 'dice-master'
    Description = 'Can roll the dice'
  }
  'Builtin:view' = @{
    Plugin = 'Builtin'
    Name = 'view'
    Description = 'Can display details about running bot instance'
  }
  'Builtin:view-role' = @{
    Plugin = 'Builtin'
    Name = 'view-role'
    Description = 'Can view details about roles defined in bot'
  }
  'Builtin:view-group' = @{
    Plugin = 'Builtin'
    Name = 'view-group'
    Description = 'Can view details about groups defined in bot'
  }
  'Builtin:manage-groups' = @{
    Plugin = 'Builtin'
    Name = 'manage-groups'
    Description = 'Can create/create/update/delete groups'
  }
}
```

### Plugins.psd1

This file holds the list of loaded plugins (and versions) in the bot.
It is possible that multple versions of a plugin are loaded at the same time.
As plugins are loaded/unloaded/enabled/disabled this file will reflect the status of each plugin.
When PoshBot starts, the plugins defined in this file are loaded and are available for use.

#### Example plugins.psd1

```powershell
@{
  NameIT = @{
    '1.8.3' = @{
      ManifestPath = 'C:\Users\joeuser\Documents\WindowsPowerShell\Modules\NameIT\1.8.3\NameIT.psd1'
      Name = 'NameIT'
      Version = '1.8.3'
      Enabled = $True
    }
  }
  Demo = @{
    '1.0.0' = @{
      ManifestPath = 'C:\Users\joeuser\Documents\WindowsPowerShell\Modules\PoshBot\Plugins\Demo\Demo.psd1'
      Name = 'Demo'
      Version = '1.0.0'
      Enabled = $True
    }
  }
  Network = @{
    '1.0.0' = @{
      ManifestPath = 'C:\Users\joeuser\Documents\WindowsPowerShell\Modules\PoshBot\Plugins\Network\Network.psd1'
      Name = 'Network'
      Version = '1.0.0'
      Enabled = $True
    }
  }
}

```

### Roles.psd1

This file holds the list of roles (and associated permissions) that have been created for securing access to commands.
As roles are created/removed/updated via bot commands, this file will be updated.
When PoshBot starts, this file is loaded so role definitions are not lost between bot restarts.

#### Example roles.psd1

```powershell
@{
  Admin = @{
    Description = 'Bot administrator role'
    Permissions = @('Builtin:show-help','Builtin:view-group','Builtin:view','Builtin:manage-roles','Builtin:manage-groups','Builtin:view-role','Builtin:manage-plugins')
  }
  'network-operator' = @{
    Description = 'packer pusher'
    Permissions = @('Network:test-network')
  }
}

```
