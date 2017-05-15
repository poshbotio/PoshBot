
# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [0.3.0] Unreleased
### Added
- Ability to override command name via the [PoshBot.BotCommand] attribute.
- Ability to set aliases for a command via the [PoshBot.BotCommand] attribute.
- Ability to use [array] and [switch] parameter values for commands.
- Code block support to custom text response via New-PoshBotTextResponse.
- File upload support via new custom response function New-PoshBotFileUpload.

## [0.2.3] Unreleased
### Fixed
- Respect changes to [Admin] role that are saved to storage.

### Added
- New global variable $global:PoshBotContext inserted into PowerShell job so commands have extra context detailing how the command was triggered.

## [0.2.2] 2017-04-17
### Fixed
- Command tokenization issues on Nano Server.
- #24: Nano Server compatability

## [0.2.1] 2017-04-14
### Fixed
- #23: Issue with retrieving module command attribute type names on Nano server.

## [0.2.0] 2017-04-06
### Added
- Commands to create and assign adhoc permissions

## [0.1.3] Unreleased
### Added
- New builtin command [Find-Plugin] to find available plugins in the desired PowerShell repository

## [0.1.2] - 2017-03-24
### Fixed
- Bot command names are now set to the value of the CommandName property of [PoshBot.BotCommand()] if defined. Previously, this didn't work and the bot command names always used the function name
- Fixed a bug in the builtin command [Install-Plugin] where if specified, the specific version of a plugin to install produced an error

## [0.1.1] - 2017-03-23
### Fixed error in !install-plugin command when installing plugins that had a dependency on the PoshBot module.

## [0.1.0] - 2017-03-21
### Added
- Initial documentation for mkdocs
- New function to create scheduled task to run PoshBot
- New builtin command to get recent command execution history
- Commands to remove plugins/roles/groups
- Support for multiple plugin versions

### Changed
- Standadized builtin bot command parameter names
- Move demo commands (WolframAlpha, Giphy) into seperate plugin repos
- Move network plugin into seperate repo

### Fixed
- Fix StopUpstreamCommandsException exception from being thrown in Install-Plugin command

## [0.0.1] - 2016-12-18
### Added
- Initial commit
