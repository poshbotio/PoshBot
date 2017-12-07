
# Channel Rules

Channel rules allow the bot administrator to control what channels PoshBot is allowed to interact in, and optionally, what commands are allowed in those channels. Channel rules are evaluated in order, so it is best to specify them from most specific to least specific. Once a command is matched to a channel rule, evaluation is stopped.

> When PoshBot receives a command to run, it resolves it to a fully qualified command name `<pluginname>.<commandname>.<version>`. This fully qualified name is what is evaluated against the channel rules. Even though a user may have entered an [alias](../tutorials/plugin-development/advanced/poshbot.botcommand-attribute.md#aliases) for a command, the real command name is checked. Because of this, when using channel rules, the **actual** command name must be used and not any aliases.

> Note that by default, channel rules allow all commands to be executed in any channel PoshBot is participating in. If you do not explicitly define a value for `ChannelRules`, the value `@(@{Channel = '*'; IncludeCommands = @('*'); ExcludeCommands = @()})` is used. **Once you define channel rules, those rules take precedence and PoshBot will only honor commands that match the rules.**

## Potential Scenarios

* PoshBot should be confined to only certain channels on the chat network.
* Some plugins or commands are particularly sensitive and there is a need to tightly control what channels those plugins/commands are executed in.
* There is a need to whitelist or blacklist certain plugins/commands from one or more channels.

## Examples

### Confine PoshBot to just the `bots` channel

#### mybot.psd1

```powershell
@{
    ChannelRules = @(
        @{
            Channel = 'bots'
            IncludeCommands = @('*')
            ExcludeCommands = @()
        }
    )
}
```

### Only allow builtin commands in the `botadmin` channel

```powershell
@{
    ChannelRules = @(
        @{
            Channel = 'botadmin'
            IncludeCommands = @('builtin:*')
            ExcludeCommands = @()
        }
    )
}
```

### Exclude the `PoshBot.Giphy` plugin from the `general` and **only** allow that plugin in the `random` channel

```powershell
@{
    ChannelRules = @(
        @{
            Channel = 'general'
            IncludeCommands = @('*')
            ExcludeCommands = @('poshbot.giphy:*')
        }
        @{
            Channel = 'random'
            IncludeCommands = @('poshbot.giphy:*')
            ExcludeCommands = @()
        }
    )
}
```

### Only allow the `ProjectX` plugin in the multiple `Project X` channels along with the `Get-CommandHelp` command.

```powershell
@{
    ChannelRules = @(
        @{
            Channel = '*project_x*'
            IncludeCommands = @(
                'ProjectX:*'
                'builtin:*'
            )
            ExcludeCommands = @()
        }
    )
}
```

### Only allow version `1.2.3` of the `foo` plugin in the `general` channel. All other plugins are allowed

```powershell
@{
    ChannelRules = @(
        @{
            Channel = 'general'
            IncludeCommands = @(
                'foo:*:1.2.3'
                '*'
            )
            ExcludeCommands = @()
        }
    )
}
```
