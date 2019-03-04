
# Quickstart

To get started, get a **SLACK-API-TOKEN** for your bot:

[https://my.slack.com/services/new/bot](https://my.slack.com/services/new/bot)

You will also need to gather the Slack username(s) of your Bot Admins. The username can be found in your _Slack Account > Settings > Username_ > click expand. Enter it using the format `@username` into the `BotAdmins` array.

```powershell
# Install the module from PSGallery
Install-Module -Name PoshBot -Repository PSGallery

# Import the module
Import-Module -Name PoshBot

# Create a bot configuration
$botParams = @{
    Name = 'name'
    BotAdmins = @('@<SLACK-CHAT-HANDLE>')
    CommandPrefix = '!'
    LogLevel = 'Info'
    BackendConfiguration = @{
        Name = 'SlackBackend'
        Token = '<SLACK-API-TOKEN>'
    }
    AlternateCommandPrefixes = 'bender', 'hal'
}

$myBotConfig = New-PoshBotConfiguration @botParams

# Start a new instance of PoshBot interactively or in a job.
Start-PoshBot -Configuration $myBotConfig #-AsJob
```
