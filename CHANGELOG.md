
# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [0.10.3] Unreleased

### Fixed

- Start-PoshBot with -AsJob switch now works correctly.

## [0.10.2] 2018-05-04

### Fixed

- Fixed check for Windows by evaluating the `$IsWindows` variable correctly.

## [0.10.1] 2018-04-05

### Fixed

- Fixed default PoshBot directory paths to work on macOS and Linux.

## [0.10.0] 2017-12-13

### Added

- [**#71**](https://github.com/poshbotio/PoshBot/pull/71) Added `-Examples` and `-Full` switches to builtin command `Get-CommandHelp`. These switches provide more information about a command and `-Examples` is particularly useful when learning how to use a command. These provide a similar experience to PowerShell's `Get-Help` cmdlet. (via [@RamblingCookieMonster](https://github.com/RamblingCookieMonster))

- [**#72**](https://github.com/poshbotio/PoshBot/pull/72) Added `FormatEnumerationLimitOverride` property with a default value of `-1` to the bot configuration. This controls the enumeration limit of arrays and addresses an issue where not all items in an array would be displayed if the array had more than `4` items (the default limit). Instead an ellipsis `...` would be shown. (via [@RamblingCookieMonster](https://github.com/RamblingCookieMonster))

### Fixed

- An exception was raised when running `Save-PoshBotConfiguration`.

- Logic bug where the `SendCommandResponseToPrivate` configuration property was not being honored.

- [**#73**](https://github.com/poshbotio/PoshBot/pull/73) Command resolution when running builtin command `Get-CommandHelp` was returning unexpected results. (via [@RamblingCookieMonster](https://github.com/RamblingCookieMonster))

## [0.9.0] 2017-12-06

### Added

- PoshBot can now be constrained to certain channels via a whitelist in the bot configuration. Commands initiated from other channels will be ignored.

- Direct messages (DMs) to the bot can be disallowed via configuration.

### Fixed

- Configuration settings for commands requiring approval were not being saved to disk correctly.

## [0.8.0] 2017-10-01

### Added

- Commands can now be marked as needing approval by someone in a designated group. Commands that require approval will be put into a pending state with an expiration time set via the bot configuration. These pending commands can be approved by the calling user (if calling user is already in designed approval group) or require peer approval by another user. Pending commands can either be approved or denied by a user in the approver group(s). Who approved (or denied) a command is logged.

- Added builtin commands [approve], [deny], and [pending] to managed commands that require approval.

- Added new message reactions to reflect pending / approved, or denied command status.

- For convenience, added the name of the user [FromName] and name of the channel [ToName] to the [$global:PoshBotContext] object that is available to all bot commands.

### Fixed

- Ignore ephemeral messages from Slack that come from SlackBot. We don't want to attempt to trigger commands based on these.

- Config provided parameters can now be used on commands of type [regex].

- Do not send command reactions to event-triggered commands as there is not a normal message to add the reaction to.

### Changes

- Modules are now removed from the PowerShell session when removed from PoshBot.

- Add warning reaction to commands that have any items in the warning stream of the job.

## [0.7.1] 2017-09-03

### Fixed

- Bugs in [CommandParser] class when parsing certain strings (particularly complex urls and @mentions)

### Changes

- The Slack backend will now translate @mentions that are internally referenced by Id into a username. '<@U4AM3SYI8>' becomes '@devblackops'

## [0.7.0] 2017-08-29

### Added

- Support for importing PowerShell modules that include cmdlets as well as functions. Note that custom PoshBot metadata to control command name, aliases, command type, etc is currently not supported on cmdlets.

- New bot configuration properties [MaxLogSizeMB] and [MaxLogsToKeep] to control log file size and rotation.

- Command execution history is now logged by default to a separate log file [CommandHistory.log]. Command history log settings can be controlled with configuration properties [LogCommandHistory],[CommandHistoryMaxLogSizeMB], and [CommandHistoryMaxLogsToKeep].

- New [slap] command to slap a user with a large trout (via @jaapbrasser)

### Changes

- Implemented and improved information, verbose, and debug logging throughout PoshBot.

### Fixed

- Bug where parser was incorrectly parsing URLs in command string

- Bug where users who had no permissions assigned via groups/roles where being prevented from executing commands that had no permissions attached to them.

- Improved reconnection logic and logging in Slack backend implementation.

## [0.6.0] 2017-07-18

### Added

- New builtin command 'Update-Plugin' which updates an existing plugin to a newer version and optionally removes all previous versions.

- New command [Get-CommandStatus] to show running commands.

### Fixed

- Better error handling logic when parsing command help.

- Use [Configuration] module when reading in bot configuration with [Get-PoshBotConfiguration] so PSCredentials can be deserialized correctly.

- Improved user name/id resolution to avoid Slack API rate limits.

- Fixed regression when using the [PoshBot.BotFrom()] custom attribute with an empty parameter.

- PR46 - Adjust help filter in [Get-CommandHelp] command to match exact first and display results if exactly one command was matched. Continue with existing behavior if more than one command is returned. (via @RamblingCookieMonster)

## [0.5.0] 2017-06-14

### Added
- Any regex group matches are now passed in the [Arguments] parameter to the function/command.

- Ability to specify a version of a loaded plugin command to execute. Use `plugin:command:version` or `command:version` syntax to execute the command from a specific version of the plugin.

- Support for one time scheduled commands. Commands can now be scheduled to execute once after the specified start date/time.

- Improved the help usage text for commands.

- The [!help] command now matches against command aliases as well.

### Fixed

- Help syntax now reflects the command name (as known in PoshBot) instead of PowerShell function name.

### Changed

- Command usage help is now displayed differently according to the command's trigger type. For [Command] trigger types, the command/function's parameters are show, for [Regex] trigger types, the trigger regex expression is shown.

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

- #24: Nano Server compatibility

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

### Fixed

- Fixed error in !install-plugin command when installing plugins that had a dependency on the PoshBot module.

## [0.1.0] - 2017-03-21

### Added

- Initial documentation for mkdocs

- New function to create scheduled task to run PoshBot

- New builtin command to get recent command execution history

- Commands to remove plugins/roles/groups

- Support for multiple plugin versions

### Changed

- Standardized builtin bot command parameter names

- Move demo commands (WolframAlpha, Giphy) into separate plugin repos

- Move network plugin into separate repo

### Fixed

- Fix StopUpstreamCommandsException exception from being thrown in Install-Plugin command

## [0.0.1] - 2016-12-18

### Added

- Initial commit
