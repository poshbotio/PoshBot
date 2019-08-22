
# PoshBot

| Azure Pipelines | Documentation | PS Gallery | License
|--------|--------------------|------------|-----------|
[![Azure Pipelines Build Status][azure-pipeline-badge]][azure-pipeline-build] | [![Documentation Status][docs-badge]][docs] | [![PowerShell Gallery][psgallery-badge]][psgallery] | [![License][license-badge]][license]
<!-- [![Patreon](https://img.shields.io/badge/patreon-donate-yellow.svg)](https://www.patreon.com/devblackops/memberships) -->

---

<h2 align="center">Supporting PoshBot</h2>

PoshBot is a MIT-licensed open source project. Ongoing development is made possible thanks to the support of sponsors.
If you'd like to become a sponsor, you can do so through [GitHub Sponsors](https://github.com/users/devblackops/sponsorship) or [Patreon](https://www.patreon.com/bePatron?u=10352866).

<h4 align="center">Silver Sponsors</h4>

<div align="center">
<a href="https://chocolatey.org/" target="_blank" rel="noopener noreferrer"><img src="Media/sponsors/chocolatey_logo_long.png" height="70px"></a>
</div>

---

Want some in-depth guides? Check out [ChatOps the Easy Way](https://leanpub.com/chatops-the-easy-way) on [Leanpub](https://leanpub.com/)!

<p align="center">
    <a href="https://leanpub.com/chatops-the-easy-way" target="_blank" title="ChatOps the Easy Way">
        <img src="https://s3.amazonaws.com/titlepages.leanpub.com/chatops-the-easy-way/medium?1530164567" alt="ChatOps the Easy Way">
    </a>
</p>


# Introduction

PoshBot is a chat bot written in [PowerShell](https://msdn.microsoft.com/powershell).
It makes extensive use of classes introduced in PowerShell 5.0.
PowerShell modules are loaded into PoshBot and instantly become available as bot commands.
PoshBot currently supports connecting to Slack to provide you with awesome ChatOps goodness.

<!-- <p align="center">
  <img style="height:250px;" src="https://raw.githubusercontent.com/poshbotio/PoshBot/master/Media/poshbot_logo_300_432.png" alt="PoshBot logo"/>
</p> -->

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

## [YouTube] PowerShell Summit 2018 - Invoke-ChatOps: Level up and change your culture with chat and PowerShell

[![Alt text](https://i.ytimg.com/vi/Mrs49IdnSHc/hqdefault.jpg?sqp=-oaymwEZCNACELwBSFXyq4qpAwsIARUAAIhCGAFwAQ==&rs=AOn4CLDdWnuXllwxfDRO_LGa0h_h_VGPPQ)](https://youtu.be/Mrs49IdnSHc)

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
Function        Get-PoshBot                                        0.11.4     poshbot
Function        Get-PoshBotConfiguration                           0.11.4     poshbot
Function        Get-PoshBotStatefulData                            0.11.4     poshbot
Function        New-PoshBotCardResponse                            0.11.4     poshbot
Function        New-PoshBotConfiguration                           0.11.4     poshbot
Function        New-PoshBotFileUpload                              0.11.4     poshbot
Function        New-PoshBotInstance                                0.11.4     poshbot
Function        New-PoshBotMiddlewareHook                          0.11.4     poshbot
Function        New-PoshBotScheduledTask                           0.11.4     poshbot
Function        New-PoshBotSlackBackend                            0.11.4     poshbot
Function        New-PoshBotTeamsBackend                            0.11.4     poshbot
Function        New-PoshBotTextResponse                            0.11.4     poshbot
Function        Remove-PoshBotStatefulData                         0.11.4     poshbot
Function        Save-PoshBotConfiguration                          0.11.4     poshbot
Function        Set-PoshBotStatefulData                            0.11.4     poshbot
Function        Start-PoshBot                                      0.11.4     poshbot
Function        Stop-Poshbot                                       0.11.4     poshbot
```

[azure-pipeline-badge]: https://dev.azure.com/devblackops/PoshBot/_apis/build/status/PoshBot-CI
[azure-pipeline-build]: https://dev.azure.com/devblackops/PoshBot/_build/latest?definitionId=3
(https://dev.azure.com/dotnet/ReactiveUI/_build/latest?definitionId=11)
[docs-badge]: https://readthedocs.org/projects/poshbot/badge/?version=latest
[docs]: http://poshbot.readthedocs.io/en/latest/
[psgallery-badge]: https://img.shields.io/powershellgallery/dt/poshbot.svg
[psgallery]: https://www.powershellgallery.com/packages/poshbot
[license-badge]: https://img.shields.io/github/license/poshbotio/poshbot.svg
[license]: https://www.powershellgallery.com/packages/poshbot
