
# PoshBot

[![Build status](https://ci.appveyor.com/api/projects/status/9em7etgtlmeax7gl?svg=true)](https://ci.appveyor.com/project/devblackops/poshbot)
[![Documentation Status](https://readthedocs.org/projects/poshbot/badge/?version=latest)](http://poshbot.readthedocs.io/en/latest/)

PoshBot is a chat bot written in [PowerShell](https://msdn.microsoft.com/powershell).
It makes extensive use of classes introduced in PowerShell 5.0.
PowerShell modules are loaded into PoshBot and instantly become available at bot commands.
PoshBot currently supports connecting to Slack to provide you with awesome ChatOps goodness.

<p align="center">
  <img src="https://github.com/devblackops/PoshBot/raw/master/Media/poshbot_logo_300_432.png" alt="PoshBot logo"/>
</p>

> Detailed documentation can be found at [ReadTheDocs](http://poshbot.readthedocs.io/en/latest/)

## Quickstart

To get started now, get a SLACK-API-TOKEN for your bot:

[https://api.slack.com/bot-users](https://api.slack.com/bot-users)

```powershell
# Clone the repo
git clone https://github.com/devblackops/PoshBot.git

# Install dependencies
Find-Module Configuration, PSSlack | Install-Module -Scope CurrentUser

# Import the module
Import-Module .\PoshBot\PoshBot

# Create a bot configuration
$botParams = @{
    Name = 'name'
    BotAdmins = @('slack-chat-handle')
    CommandPrefix = '!'
    LogLevel = 'Info'
    BackendConfiguration = @{
        Name = 'SlackBackend'
        Token = 'SLACK-API-TOKEN'
    }
    AlternateCommandPrefixes = 'bender', 'hal'
}

$myBotConfig = New-PoshBotConfiguration @botParams

# Start a new instance of PoshBot interactively or in a job.
Start-PoshBot -Configuration $myBotConfig #-AsJob
```

Basic usage:

```powershell
# Create a Slack backend
$backendConfig = @{Name = 'SlackBackend'; Token = 'SLACK-API-TOKEN'}
$backend = New-PoshBotSlackBackend -Configuration $backendConfig

# Create a PoshBot configuration
$pbc = New-PoshBotConfiguration -BotAdmins @('<my-slack-handle>') -BackendConfiguration $backendConfig

# Save configuration
Save-PoshBotConfiguration -InputObject $pbc -Path .\PoshBotConfig.psd1

# Load configuration
$pbc = Get-PoshBotConfiguration -Path .\PoshBotConfig.psd1

# Create an instance of the bot
$bot = New-PoshBotInstance -Configuration $pbc -Backend $backend

# Start the bot
$bot.Start()


# Available commands
Get-Command -Module PoshBot

CommandType     Name                                               Version    Source
-----------     ----                                               -------    ------
Function        Get-PoshBot                                        1.0        PoshBot
Function        Get-PoshBotConfiguration                           1.0        PoshBot
Function        New-PoshBotCardResponse                            1.0        PoshBot
Function        New-PoshBotConfiguration                           1.0        PoshBot
Function        New-PoshBotInstance                                1.0        PoshBot
Function        New-PoshBotSlackBackend                            1.0        PoshBot
Function        New-PoshBotTextResponse                            1.0        PoshBot
Function        Save-PoshBotConfiguration                          1.0        PoshBot
Function        Start-PoshBot                                      1.0        PoshBot
Function        Stop-Poshbot                                       1.0        PoshBot
```
