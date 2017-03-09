
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
Import-Module .\PoshBot.psd1
. .\test
$bot.start()
```
