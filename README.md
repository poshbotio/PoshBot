
# PoshBot

PoshBot is a chat bot written in [PowerShell](https://msdn.microsoft.com/powershell).
It makes extensive use of classes introduced in PowerShell 5.0.
PowerShell modules are loaded into PoshBot and instantly become available at bot commands.
PoshBot currently supports connecting to Slack to provide you with awesome ChatOps goodness.

<p align="center">
  <img src="https://github.com/devblackops/PoshBot/raw/master/Media/poshbot_logo_300_432.png" alt="PoshBot logo"/>
</p>

## Quickstart

PoshBot is currently under active development.
Docs will be coming soon.

To get started now, set the environment variable SLACK_TOKEN to your bot token.

[https://api.slack.com/bot-users](https://api.slack.com/bot-users)

```powershell
Import-Module .\PoshBot.psd1
. .\test
$bot.start()
```
