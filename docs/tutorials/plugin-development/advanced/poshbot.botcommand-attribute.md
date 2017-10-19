# Custom Attribute - [PoshBot.BotCommand()]

## Adding metadata to functions

PoshBot exposes a custom attribute (used similarly to `[cmdletbinding()]`) that alters the functionality of an imported command in a few ways.
By adding `[PoshBot.BotCommand()]` to a functions' `param` block, you can do things like alter the commands name in PoshBot, attach permissions, set regex triggers, etc.

Here is the `Invoke-HelloWorld` function from [Plugin Development - Simple](..\simple.md) guide.
There is nothing PoshBot-specific about this function and will behave the same in PoshBot as it would from the command line.

```powershell
function Invoke-HelloWorld {
    Write-Output 'Hi from PoshBot!'
}
```

Add `[PoshBot.BotCommand()]` to the function along with an empty `param()` block.
While you're at it, add `[cmdletbinding()]` to make this an [Advanced Function](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions_advanced?view=powershell-5.1).

> Note that by using the `[PoshBot.BotCommand()]` attribute, you are creating a dependency between your module and PoshBot. **This requires that you set `RequiredModules = 'PoshBot'` in your module manifest.**

```powershell
function Invoke-HelloWorld {
    [PoshBot.BotCommand()]
    [cmdletbinding()]
    param()

    Write-Output 'Hi from PoshBot!'
}
```

## Available Properties

The `[PoshBot.BotCommand()]` custom attribute has the following properties that you can set to alter the behavior of the command.

| Property       | Type     | Description |
| :--------------|:---------|:------------|
| CommandName    | string   | The name of the bot command. Default is the function name
| Aliases        | string[] | Alternate name(s) for the command
| TriggerType    | string   | The type of trigger. Values: `Command`, `Regex`, `Event`
| HideFromHelp   | bool     | Whether to hide the command when the !help command is used. Default is `$false`
| Regex          | string   | A regex string to match the command against. Only valid when TriggerType is `Regex`
| MessageType    | string   | Type of message this command is triggered against. Only valid when TriggerType is `Event`
| MessageSubtype | string   | Subtype of message this command is triggered against. Only valid when TriggerType is `Event`
| Permissions    | string[] | String array of permissions to apply to the command. Only users with the given permissions are allow to execute command
| KeepHistory    | bool     | Control whether command execution history is kept

### Renaming Command Names

Best practice naming conventions for Powershell functions/cmdlets is `[verb]-[noun]`.
This is still true for PoshBot plugins but when executing commands in a chat window, but sometimes brevity is better.
In order to have the command be known by a **completely different** name in PoshBot, the `CommandName` property can be set.
This property overrides the name of the command in PoshBot.

> You will **not** be able to use call the command by the original function name when setting `CommandName` to something else.
To PoshBot, the command name is only what is set in the `CommandName` property.

```powershell
function Invoke-HelloWorld {
    [PoshBot.BotCommand(
        CommandName = 'hi'
    )]
    [cmdletbinding()]
    param()

    Write-Output 'Hi from PoshBot!'
}
```

### Aliases

Sometimes you want a command to be known by multiple names.
To enable this, you can add one or more aliases to `[PoshBot.BotCommand()].
PoshBot attempts to match a message entered by the user to a registered command by its name as well as any aliases.

```powershell
function Invoke-HelloWorld {
    [PoshBot.BotCommand(
        CommandName = 'hi'
        Aliases = ('hello', 'helloworld')
    )]
    [cmdletbinding()]
    param()

    Write-Output 'Hi from PoshBot!'
}
```

### Trigger Type

A trigger tells PoshBot what to look for in an incoming chat message.
Upon receiving a message, PoshBot will search through all loaded plugins and looking for a command trigger that matches the message.
The most common trigger type will be `Command` which tells PoshBot to look at the text of the message and determine if it is a command string.

#### Command

> Command triggers are only invoked when the first character of the message is the configured `CommandPrefix` as set in the [bot configuration](../../../guides/configuration.md).

> By default, the trigger type for commands is `Command`.
You do not need to set the `TriggerType` property unless you want to change it to the below alternatives.

##### Example 1

The default configuration sets the command prefix to `!`.
The syntax for executing the command would be:

```
!invoke-helloworld'
```

##### Example 2

If an `alternate command prefix` like `bender` has been defined, the syntax for executing the command would be:

```
bender, invoke-helloworld'
```

#### Event

This trigger type listens for certain event message types that the chat network returns.
Events like a user entering or exiting a room, channel topic change, a user's presence status is changed, etc.
When a message is received by PoshBot, it will evaluate the message type and look for commands that have registered a trigger `MessageType` and optionally a `MessageSubtype` that matches the incoming message.
When one is found, the command will be executed.

> When setting the trigger type to `Event`, the `MessageType` and `MessageSubType` properties can also be set to specify the exact type of event that will trigger this command.

```powershell
function Write-ChannelTopicChange {
    <#
    .SYNOPSIS
        Responds to channel topic change events
    #>
    [PoshBot.BotCommand(
        Command = $false,
        TriggerType = 'event',
        MessageType = 'Message',
        MessageSubType = 'ChannelTopicChanged'
    )]
    [cmdletbinding()]
    param(
        [parameter(ValueFromRemainingArguments)]
        $Dummy
    )

    Write-Output 'I kind of liked the old topic'
}
```

##### MessageTypes

- **Message** - A message was entered by a user

    Subtypes:

    - **None** - No message subtype
    - **ChannelJoined** - A member joined a channel
    - **ChannelLeft** - A member left a channel
    - **ChannelRenamed** - A channel was renamed
    - **ChannelPurposeChanged** - A channel purpose was updated
    - **ChannelTopicChanged** - A channel topic was updated

- **ChannelRenamed** - The name of the channel was renamed

    Subtypes:

    - **None**

- **PinAdded** - A pin was added to a message

    Subtypes:

    - **None**

- **PinRemoved** - A pin was removed from a message

    Subtypes:

    - **None**

- **PresenceChange** - The online presence of a user has changed

    Subtypes:

    - **None**

- **ReactionAdded** - A reaction was added to a message

    Subtypes:

    - **None**

- **ReactionRemoved** - A reaction was removed from a message

    Subtypes:

    - **None**

- **StarAdded** - A star was added to a message

    Subtypes:

    - **None**

- **StarAdded** - A start was removed from a message

    Subtypes:

    - **None**

#### Regex

Regex trigger types evaluate the text of the incoming message against a regular expression for the command.
This trigger type is useful if you want a command to be casually listening in the chat room and matching each message against it's regex trigger.

> When PoshBot evaluates the regex expression, it collects the regex capture groups and passes them to the `Arguments` parameter of the function.

> You **must** define an `Arguments` parameter of type `[object[]]` in order for PoshBot to send the parameters captured from the regex expression to the function.

This command will match every incoming chat message against the regex `'cookies'`.
If a user types something like **"I bought some Girl Scout cookies yesterday"** PoshBot will execute this command and return a message saying **"Did someone mention cookies? I love cookies! Nom Nom Nom!"**

```powershell
function Cookies {
    <#
    .SYNOPSIS
        Respond to cookies
    #>
    [PoshBot.BotCommand(
        Command = $false,
        CommandName = 'cookies',
        TriggerType = 'regex',
        Regex = 'cookies'
    )]
    [cmdletbinding()]
    param(
        [parameter(ValueFromRemainingArguments = $true)]
        [object[]]$Arguments
    )

    Write-Output 'Did someone mention cookies? I love cookies! Nom Nom Nom!'
}
```

This command will match every incoming chat message against the regex `'^grafana\s(cpu|disk)\s(.*)'`.
This regex expects the word `grafana` to start at the beginning of the line and the next word to be `cpu` or `disk`.
The next word can be anything.

```powershell
function Get-GrafanaGraph {
    <#
    .SYNOPSIS
        Displays a Grafana graph for a given type for a server.
    .EXAMPLE
        grafana cpu server01
    .EXAMPLE
        grafana disk myotherserver02
    #>
    [PoshBot.BotCommand(
        Command = $false,
        CommandName = 'grafana',
        TriggerType = 'regex',
        Regex = '^grafana\s(cpu|disk)\s(.*)'
    )]
    [cmdletbinding()]
    param(
        [parameter(ValueFromRemainingArguments = $true)]
        [object[]]$Arguments
    )

    $graphType = $Arguments[1]
    $computer = $Arguments[2]

    # Code to get the graph
}
```

### Permissions

Commands can be secured by attaching one or more permissions to them. If no permissions are defined, the command can be executed by anyone. See [Command Authorization](../../../guides/command-authorization\overview.md) for more information.

```powershell
function Invoke-AdminCommand {
    <#
    .SYNOPSIS
        Do something that only an administrator should be able to do.
    .EXAMPLE
        !invoke-admincommand
    #>
    [PoshBot.BotCommand(
        Permissions = 'admin-level'
    )]
    [cmdletbinding()]
    param()

    # Do something
}
```

### History

By default, every command execution is logged and kept in a small in-memory collection. If you wish to disable history for a command, you can set this property to `$false`.

```powershell
function Invoke-TempCommand {
    <#
    .SYNOPSIS
        This command doesn't do anything specials
    .EXAMPLE
        !invoke-tempcommand
    #>
    [PoshBot.BotCommand(
        KeepHistory = $false
    )]
    [cmdletbinding()]
    param()

    # Do something
}
```