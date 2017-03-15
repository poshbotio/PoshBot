
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

To get started now, set the environment variable SLACK_TOKEN to your bot token.

[https://api.slack.com/bot-users](https://api.slack.com/bot-users)

```powershell
# clone the repo
git clone https://github.com/devblackops/PoshBot.git

# install dependencies
Find-Module Configuration, PSSlack | Install-Module -Scope CurrentUser

# import the module
Import-Module .\PoshBot\PoshBot

# create a bot configuration
$backend = @{Name = 'SlackBackend'; Token = 'slack-api-token'}
$botParams = @{
    Name = 'name'
    LogLevel = 'Info'
    BotAdmins = @('slack-chat-handle')
    BackendConfiguration = $backend
}
$myBotConfig = New-PoshBotConfiguration @botParams

# save configuration
Save-PoshBotConfiguration $myBotConfig -Path .\PoshBotConfig.psd1
# load configuration
$pbc = Get-PoshBotConfiguration -Path .\PoshBotConfig.psd1

#start a new instance of PoshBot interactively or in a job.
Start-PoshBot -Configuration $pbc #-AsJob
```
