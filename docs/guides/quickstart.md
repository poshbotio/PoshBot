
# Quickstart

In order to get started, you'll need to grab a few pieces of information:

1. The API token for your bot. This allows PoshBot to participate in your Slack workspace.
1. The Slack username(s) for any bot administrators you wish to setup as part of the initial configuration process.

## Slack API Token

Slack allows for many types of custom integrations, including Bots. Bots are able to run code that listens and posts to your Slack team just as a user would. To create a Bot, visit [https://my.slack.com/services/new/bot](https://my.slack.com/services/new/bot) and follow the instructions to generate a new Bot.

Once you have a new bot, copy the `API Token` for the bot. You'll insert that into the bot configuration below by replacing the `<SLACK-API-TOKEN>` placeholder.

## Bot Administrator Username(s)

Next, you'll need the Slack username(s) of any bot administrators that need full permissions over PoshBot. Note that Slack has many different types of names associated with an account; you'll need the username, which can be found in your account settings.

_Your Slack Account > Settings > Username_ > click expand > copy the `username`.

Enter it using the format `@username` into the `BotAdmins = @('@<SLACK-CHAT-HANDLE>')` array.

# Installation Workflow

Now that you have the API Token and administrator username(s), follow the steps below to install, configure, and run PoshBot.

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
