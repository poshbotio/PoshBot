
# PoshBot

[![Build status][appveyor-badge]][appveyor-build]
[![Documentation Status][docs-badge]][docs]
[![PowerShell Gallery][psgallery-badge]][psgallery]
[![License][license-badge]][license]
<!-- [![Patreon](https://img.shields.io/badge/patreon-donate-yellow.svg)](https://www.patreon.com/devblackops/memberships) -->

<h2 align="center">Supporting PoshBot</h2>

PoshBot is a MIT-licensed open source project. Ongoing development is made possible thanks to the support of backers. If you'd like to become a backer or sponsor, you can do so on Patreon.

<p align="center">
    <a href="https://www.patreon.com/devblackops/memberships" target="_blank" title="Become a Patron">
        <img style="height:50px" src="Media/become_a_patron_button.png" alt="Become a Patron">
    </a>
</p>

# Introduction

PoshBot is a chat bot written in [PowerShell](https://msdn.microsoft.com/powershell).
It makes extensive use of classes introduced in PowerShell 5.0.
PowerShell modules are loaded into PoshBot and instantly become available as bot commands.
PoshBot currently supports connecting to Slack to provide you with awesome ChatOps goodness.

<p align="center">
  <img style="height:250px;" src="https://raw.githubusercontent.com/poshbotio/PoshBot/master/Media/poshbot_logo_300_432.png" alt="PoshBot logo"/>
</p>

## What Can PoshBot Do?

Pretty much anything you want :) No seriously.
PoshBot executes functions or cmdlets from PowerShell modules.
Use PoshBot to connect to servers and report status, deploy code, execute runbooks, query APIs, etc.
If you can write it in PowerShell, PoshBot can execute it.

## Documentation

Detailed documentation can be found at [ReadTheDocs](http://poshbot.readthedocs.io/en/latest/).

## Building PoshBot

See [Building PoshBot](./building.md) for documentation on how to build PoshBot from source.

## Changelog

Detailed changes for each release are documented in the [release notes](https://github.com/poshbotio/poshbot/releases).

## [YouTube] PoshBot Demo at the Portland User Group on 2017-05-31

[![Alt text](https://img.youtube.com/vi/36fkyKYq43c/0.jpg)](https://www.youtube.com/watch?v=36fkyKYq43cV)

## Quickstart

To get started now, get a SLACK-API-TOKEN for your bot:

[https://my.slack.com/services/new/bot](https://my.slack.com/services/new/bot)

```powershell
# Install the module from PSGallery
Install-Module -Name PoshBot -Repository PSGallery

# Import the module
Import-Module -Name PoshBot

# Create a bot configuration
$botParams = @{
    Name = 'name'
    BotAdmins = @('<SLACK-CHAT-HANDLE>')
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

Basic usage:

```powershell
# Create a Slack backend
$backendConfig = @{Name = 'SlackBackend'; Token = '<SLACK-API-TOKEN>'}
$backend = New-PoshBotSlackBackend -Configuration $backendConfig

# Create a PoshBot configuration
$pbc = New-PoshBotConfiguration -BotAdmins @('<MY-SLACK-HANDLE>') -BackendConfiguration $backendConfig

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
Function        Get-PoshBot                                        0.10.1     PoshBot
Function        Get-PoshBotConfiguration                           0.10.1     PoshBot
Function        Get-PoshBotStatefulData                            0.10.1     PoshBot
Function        New-PoshBotCardResponse                            0.10.1     PoshBot
Function        New-PoshBotConfiguration                           0.10.1     PoshBot
Function        New-PoshBotFileUpload                              0.10.1     PoshBot
Function        New-PoshBotInstance                                0.10.1     PoshBot
Function        New-PoshBotScheduledTask                           0.10.1     PoshBot
Function        New-PoshBotSlackBackend                            0.10.1     PoshBot
Function        New-PoshBotTextResponse                            0.10.1     PoshBot
Function        Remove-PoshBotStatefulData                         0.10.1     PoshBot
Function        Save-PoshBotConfiguration                          0.10.1     PoshBot
Function        Set-PoshBotStatefulData                            0.10.1     PoshBot
Function        Start-PoshBot                                      0.10.1     PoshBot
Function        Stop-Poshbot                                       0.10.1     PoshBot
```

[appveyor-badge]: https://ci.appveyor.com/api/projects/status/9em7etgtlmeax7gl?svg=true
[appveyor-build]: https://ci.appveyor.com/project/devblackops/poshbot
[docs-badge]: https://readthedocs.org/projects/poshbot/badge/?version=latest
[docs]: http://poshbot.readthedocs.io/en/latest/
[psgallery-badge]: https://img.shields.io/powershellgallery/dt/poshbot.svg
[psgallery]: https://www.powershellgallery.com/packages/poshbot
[license-badge]: https://img.shields.io/github/license/poshbotio/poshbot.svg
[license]: https://www.powershellgallery.com/packages/poshbot

