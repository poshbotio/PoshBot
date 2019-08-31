
# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [0.11.8] 2019-08-30

### Fixed

- Commands will no longer be re-executed if a user replies to the original command with a threaded message
- The formatting of large message responses to Slack has been fixed
- New-PoshBotCardResponse now accepts any object of type `System.Collections.IDictionary` instead of always casting to `System.Collections.Hashtable`. This will preserve the ordering of keys if the supplied object supports it.

## [0.11.7] 2019-08-09

### Fixed

- Added missing parameter `$PreExecuteMiddlewareHooks` to `New-PoshBotConfiguration`
- Channels rules should now work correctly with private channels in Slack
- Retrieving channels from Slack now uses paging to return ALL unarchived channels

### Changed

- Pinned modules `Configuration` to `1.3.1` and `PSSlack` to `1.0.1`

## [0.11.6] 2019-04-02

### Added

- [**#161**](https://github.com/poshbotio/PoshBot/pull/161) In Teams, send a `typing...` indicator when in private conversations with the bot.
  This mimics the behavior in Slack when it adds a `gear` icon to the message to
  indicate the bot has received the command and is processing it.
  Currently Teams only supports this functionality in private conversations with the bot. (via [@AndrewPla](https://github.com/AndrewPla))

### Fixed

- Strip extra newlines (\n) from messages received from Teams backend.
- Allow a `$null` command prefix. This is useful in backends like Teams that require you to @mention the bot (e.g. `@poshbot !status`).
  This change removes the need for a command prefix as you are already specifying a bot command by @mentioning it.
  The following syntax is now possible: `@poshbot status`

## [0.11.5] 2019-02-27

### Fixed

- [**#154**](https://github.com/poshbotio/PoshBot/pull/154) Fix command approval logic (via [@dreznicek](https://github.com/dreznicek))
- Fixed crash when a command required approval yet the calling user was not part of any groups

## [0.11.4] 2019-01-17

### Fixed

- [**#138**](https://github.com/poshbotio/PoshBot/issues/138) Enforce TLS 1.2
- [**#134**](https://github.com/poshbotio/PoshBot/pull/134) Fix missing messages in Slack backend (via [@Pilosite](https://github.com/Pilosite))
- [**#133**](https://github.com/poshbotio/PoshBot/issues/133) Fix references to middleware hooks when converting to/from hashtable

## [0.11.3] 2018-11-06

### Changes

- Reference `$global:PoshBotContext` instead of `PoshBotContext` so it's clear what variable we're using.

### Fixed

- [**#129**](https://github.com/poshbotio/PoshBot/pull/129) To avoid serialization issues when executing a command in the PS job, use the module-qualified command name instead of the function/cmdlet object returned from Get-Command. (via [@Tadas](https://github.com/Tadas))

- [**#132**](https://github.com/poshbotio/PoshBot/pull/132) By default, the `ChannelRules` property of the `[BotConfiguration]` object has a single rule that allows all commands in all channels.
This is so that when creating a new configuration object with `New-PoshBotConfiguration` and specifying no addition parameters, we have a working configuration.
When creating a new bot configuration object AND passing it one or more channels rules, we should zero out the array as it is implied by passing in channel rules that the rules should be exactly what was passed in and not IN ADDITION to the default one. (via [@DWOF](https://github.com/DWOF))

## [0.11.2] 2018-10-11

### Added

- Specifying the contents of a file to upload, as well as its file name and type are now supported in `New-PoshBotFileUpload`.
  This is in addition to the already supported feature of specifying a file path.

### Changes

- [**#122**](https://github.com/poshbotio/PoshBot/pull/122) Enable running multiple versions of PoshBot side-by-side. When PoshBot needs to load itself (via running PoshBot as a job, a scheduled task, or a plugin command), it now loads the exact version of PoshBot that is currently running instead of loading the latest version that happens to be in `$env:PSModulePath`. This enables multiple versions of PoshBot to be running and be self-contained. (via [@Tadas](https://github.com/Tadas))

### Fixed

- When starting PoshBot using `Start-PoshBot -AsJob`, determine the correct backend instance to create by validating the passed in configuration against the names `Slack`, `SlackBackend`, `Teams`, and `TeamsBackend`.

- ChannelRules in the bot configuration were not being serialized correctly if more than one hashtable entry was present.

- Match documentation and check for `SlackBackend` or `TeamsBackend` backend names when starting PoshBot as a PowerShell job.

- [**#111**](https://github.com/poshbotio/PoshBot/pull/111) Use CommandParser to strip out extra line breaks from a message received from Teams (via [@AndrewPla](https://github.com/AndrewPla))

- Resolve ambiguous method signature error in Slack backend by using an `[ArraySegment[byte[]]` buffer in the `System.Net.WebSockets.ClientWebSocket.ReceiveAsync()` method.

- [**#125**](https://github.com/poshbotio/PoshBot/pull/125) Escape prefix character when evaluating messages.
  Any single character can be defined as the prefix character (default is "!") that indicates to PoshBot that the incoming message is a bot command. Some of these characters are also regex special characters and we need to escape them properly so when people indicate they want to use the '.' or '^' characters for example, they are treated a literal. (via [@Windos](https://github.com/Windos))

- Fix bot crash when removing a scheduled command that was configured to only trigger once.

- [**#121**](https://github.com/poshbotio/PoshBot/pull/121) Prevent multiple executions of commands scheduled in the past. This fixes an issue where if the StartAfter value of a scheduled command was in the past, on bot startup the scheduled command would be executed however many intervals difference there was between the StartAfter value and the current time. (via [@AngleOSaxon](https://github.com/AngleOSaxon))

- HTML decode the message text received from the backend. This ensures characters like '&' are converted back from their encoded version '\&amp;' that may have been received.

## [0.11.1] 2018-10-01

### Fixed

- Remove obsolete DLLs associated with the Teams backend and Azure Service Bus. These DLLs are not needed and attempting to load them was causing issues in Windows PowerShell.

- [**#118**](https://github.com/poshbotio/PoshBot/pull/118) Force module import to pick up changes.
  When importing a plugin, Use "Import-Module -Force" to make PowerShell re-import the module even if it is already loaded and the version has not changed. This fixes an issue during plugin development where functions are added or modified without bumping the version number. (via [@Tadas](https://github.com/Tadas))

## [0.11.0] 2018-09-09

### Added

- Initial support for Microsoft Teams backend. To connect to Teams, additional Azure resources are required which the Teams backend will connect to. Command and regex triggers are supported. Event triggers currently are not. In group conversations, you must '@' mention the bot followed by your text message otherwise the bot will not receive it. In one-on-one conversations with the bot, '@' mentioning is not needed. More information can be found [here](https://poshbot.readthedocs.io/en/latest/guides/backends/setup-teams-backend/).

- Support for custom middleware to be executed during the command processing life cycle has been added.
  It is now possible to execute custom scripts pre/post receiving a message from the chat network, pre/post command execution, and pre/post command response.
  These execution hooks can be used for centralized authentication logic, custom command whitelisting and blacklisting, response sanitation, or any number of other uses.

- [**#89**](https://github.com/poshbotio/PoshBot/pull/89) Add `CustomData` parameter to `New-PoshBotCardResponse`.
  This enables custom backends and plugins to send additional data in a card response (via [@scrthq](https://github.com/scrthq)).

- [**#99**](https://github.com/poshbotio/PoshBot/pull/99) Add `CardClicked` event type to `MessageType` enum.
  This enables custom backends that support `CardClicked` events in interactive cards to use this event type with event-trigger based commands (via [@scrthq](https://github.com/scrthq)).

- Enable multiple groups or roles to be created or removed at once via the `New-Group`, `New-Role`, `Remove-Group`, and `Remove-Role` builtin commands.

- Added new builtin command `Get-MyCommands` which returns all loaded commands the calling user is authorized to execute.

- [**#105**](https://github.com/poshbotio/PoshBot/pull/105) Add `BackendType` property to `$global:PoshBotContext` with a value of the type of backend that is configured in PoshBot.
  This value can be used by plugin commands to change their behavior based on the type of backend (e.g., Slack, Teams, or GChat) (via [@ChrisLGardner](https://github.com/ChrisLGardner)).

### Fixed

- `Start-PoshBot` with `-AsJob` switch now works correctly.

- When removing a plugin, the PowerShell module is now also unloaded.

- [**#90**](https://github.com/poshbotio/PoshBot/pull/90) Fixed scheduling logic to fire commands at interval based on start time (via [@JasonNoonan](https://github.com/JasonNoonan))

- Fix `Get-CommandHelp` to display correct help when one item is returned.

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
