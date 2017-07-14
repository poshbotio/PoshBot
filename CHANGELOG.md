
# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [0.6.0] Unreleased
### Added
- New builtin command 'Update-Plugin' which updates an existing plugin to a newer version and optionally removes all previous versions.
- New command [Get-CommandStatus] to show running commands.

### Fixed
- Better error handling logic when parsing command help.
- Use [Configuration] module when reading in bot configuration with [Get-PoshBotConfiguration] so PSCredentials can be deserialized correctly.

## [0.5.0] 2017-06-14
### Added
- Any regex group matches are now passed in the [Arguments] parameter to the function/command.
- Ability to specify a version of a loaded plugin command to execute.
  Use `plugin:command:version` or `command:version` syntax to execute the command from a specific version of the plugin.
- Support for one time scheduled commands. Commands can now be scheduled to execute once after the specified start date/time.
- Improved the help usage text for commands.
- The [!help] command now matches against command aliases as well.

### Fixed
- Help syntax now reflects the command name (as known in PoshBot) instead of PowerShell function name.

### Changed
- Command usage help is now displayed differently according to the command's trigger type.
  For [Command] trigger types, the command/function's parameters are show, for [Regex] trigger
  types, the trigger regex expression is shown.

## [0.4.1] 2017-06-06
### Fixed
- Bug when displaying command help with !help command

## [0.4.0] 2017-06-05
### Added
- Asynchronous command execution
- Message reactions to indicate a command is executing, succeeded, or failed.
- Scheduled command functionality. Commands can now be scheduled for execution every N days/hours/minutes/seconds.

### Fixed
- Bug preventing plugin commands from being executed in PS jobs. Commands were previously being executed in the same session as the bot.
- Replaced error with warning when one of the bot configuration file is not found.

## [0.3.1] 2017-05-17
### Fixed
- When parsing the command from the message returned from the chat network, deal with null or empty text strings correctly.
- Resolve PSScriptAnalyzer warnings

## [0.3.0] 2017-05-16
### Added
- PR31: Functions to get/set/remove stateful data within plugin command (via @RamblingCookieMonster)
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
