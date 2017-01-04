
# Commands

A command is an action that the bot can make in response to a message being received from the chat network.
Multiple commands are bundled into plugins (PowerShell modules).
Commands map to functions/cmdlets in a PowerShell module.
Commands get executed (in a PowerShell job) when the bot matches the chat message to a trigger of some sort.

## Commands have

* A name (required)
* A trigger (required)
* A module command to execute (required)
* A role (optional)

## Builtin Commands

* !about
* !help
* !status

# Plugins

A plugin is a collection of commands, triggers, and associated roles.
Plugins come in the form of PowerShell modules that are loaded by the bot.

# Triggers

A trigger tells the bot what to look for in the chat message.
Upon receiving a message, the bot will search through loaded plugins looking for a command trigger that matches.
If found, that command will get executed (if enabled and allowed via roles).

## Trigger Types

* Command - Execute command by name
* Regex - Match message typed in chat to a regex expression

# Roles

Roles are associated with commands.
Users of the chat network are added to roles.
Only members of a role associated to a command can execute that command.

# Backends

Backend implement bot functionality that is specific to the chat network. This is essentially sending/receiving messages.

# Event

An event is something that happends on a chat network.
Most of the time it will be a message received event but it could be something like a user enters/leaves a room, room topic was changed, etc.
Triggers are bound to specific event types.

## Event Types

* Message received (most common)
* User entered/left room
* Room topic changed.
* User presnce change
* Reaction added to/removed from message

# Response

A response is what gets sent back to the chat network. This could be simple text or specially formatted responses.

# Storage

Storing the bot configuration in a persistent store allows for the bot to be restarted without loosing configuration data.
The most important things to store persistently are user/role associations.
