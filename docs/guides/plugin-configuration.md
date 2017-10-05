
# Plugin Configuration

PoshBot plugins are just PowerShell modules.
As such, they can be published to repositories like the PowerShell Gallery.
Often your commands will require credentials or sensitive data to be passed to them that you would not want to bundle with the plugin and distribute to others.
From the command line, you would just pass the parameter value to the function.
Inside a chat window though, you wouldn't want to (or in the case of PS credentials) **can't** supply the command with the value(s) it needs.
PoshBot handles this with a property called `PluginConfiguration` in your [configuration](.\configuration.md) file.
`PluginConfiguration` is where you can store parameters values that Poshbot will **dynamically** supply to your command at execution time.
This is the perfect spot to store credentials, API keys, etc that you don't want to distribute with your plugin.

The `PluginConfiguration` property is just a hashtable where the key(s) are the names of the plugins you have loaded.
The value of each key is itself another hashtable where the keys match a parameter name in one or more commands of that plugin.
A plugin command can specify that a parameter gets its value from this configuration by applying the custom attribute `[PoshBot.FromConfig()]` on the parameter.

## Example

Let's say we have a plugin called `MyPlugin` with a command called `Get-Foo`.
We have a sensitive parameter that is required for this command but we don't want to distribute that value with the plugin.
Inside the function, we declare that the value of `MyParam` will be supplied from the bot configuration by decorating the parameter with the `[PoshBot.FromConfig()]` custom attribute.

```powershell
function Get-Foo {
    [cmdletbinding()]
    param(
        [PoshBot.FromConfig()]
        [parameter(mandatory)]
        [string]$MyParam
    )

    Write-Output $MyParam
}
```

The `PluginConfiguration` section of our bot configuration will include a hashtable entry for `MyPlugin` and a value for the `MyParam` parameter.

```powershell
@{
    PluginConfiguration = @{
        MyPlugin = @{
            MyParam = 'hunter2'
        }
    }
}
```

At command execution time, PoshBot will detect that `Get-Foo` is asking for a value for `MyParam` and attempt to resolve the value from `PluginConfiguration`. If a matching value is found, PoshBot will pass it to the cmdlet/function as a named parameter.

> PoshBot will only return values associated with the plugin of the calling command. **You do not have access to values associated with other plugins.**

## Overriding Parameter Names

By default, PoshBot will look for a plugin configuration key that is the **same** name as the parameter name. If you wish to store values under a different name than the parameter name, you can specify the custom key name with `[Poshbot.FromConfig('<my_key_name>')]`.

### Example

In this example our parameter name is `ApiKey` but the value we with to pull from configuration is stored under `MySecretApiKey`. We specify the custom key name `[PoshBot.FromConfig('MySecretApiKey')]`.

```powershell
function Get-Foo {
    [cmdletbinding()]
    param(
        [PoshBot.FromConfig('MySecretApiKey')]
        [parameter(mandatory)]
        [string]$ApiKey
    )

    Write-Output $MyParam
}
```

```powershell
@{
    PluginConfiguration = @{
        MyPlugin = @{
            MySecretApiKey = 'hunter2'
        }
    }
}
```

In the examples above, we've stored plain text strings inside the `PluginConfiguration` section. You wouldn't want to store secrets as plain text values though. Fortunately, Poshbot supports storing `PSCredential` and `SecureString` objects inside the bot config `psd1`.

> When saving the bot configuration to a `psd1`, if `PSCredential` or `SecureString` objects are used within `PluginConfiguration`, only the user who exported the configuration (and the original machine) can successfully import it using `Get-PoshbotConfiguration`.

```powershell
$pbc = New-PoshBotConfiguration
$pbc.PluginConfiguration = @{
    MyPlugin = @{
        Credential = (Get-Credential)
    }
}
$pbc | Save-PoshBotConfiguration -Path c:\temp\bot.psd1
```

#### bot.psd1

```powershell
@{
    ###
    # other bot properties omitted
    ###    
    PluginConfiguration = @{        
        MyPlugin = @{
            Credential = (PSCredential "joeuser" "01000000d08c9ddf0115d1118c7a00c04fc297eb0100000060ae863578849c4680a57d65f2994eff00000000020000000000106600000001000020000000cd8c90628fc9f7fd332869a0e30eec41cbje8c531618375f22bfa84a2a53e132000000000e80000000020000200000003b7027c1f5577bd36f7f9c87db7bb427f4808466758eb9a579e36be9bc49b3481000000092223e3261d78e6547ed0f799f5462eb400000008hpddfa3619fcc7b56bb2571b8cc9405740bf266e1fd8fc79b9nj1203ad9058d19a73eb75f5d977ef4478dc9f207f21e19c95affd1d44eca0b405f879e3c98nu")
            }
        }
    }
}
```

An alternative to storing plugin configuration items in the `psd1` and then reading it in via `Get-PoshBotConfiguration`, is to build out your bot configuration at runtime and then pass that object to `Start-PoshBot`. This method allows you to retrieve your plugin configuration items in any way you see fit. Maybe you have logic to retrieve values from the Windows credential store or a password vault.

## Example

Say you had some custom PowerShell functions called `Get-MyPoshBotAdmins`, `Get-MyPoshBotSlackToken`, and `Get-PoshBotPluginConfigurationItem`. These functions retrieve values from a configuration management database that you maintain. You can use these functions to dynamically build the PoshBot configuration and then pass it to `Start-PoshBot`.

```powershell
$botParams = @{
    Name = 'name'
    BotAdmins = Get-MyPoshBotAdmins
    CommandPrefix = '!'
    LogLevel = 'Info'
    BackendConfiguration = @{
        Name = 'SlackBackend'
        Token = Get-MyPoshBotSlackToken
    }
    AlternateCommandPrefixes = 'bender', 'hal'
    PluginConfiguration = @{
        MyPlugin = @{
            Credential = Get-PoshBotPluginConfigurationItem -Plugin MyPlugin -Name Credential
        }
    }
}

$myBotConfig = New-PoshBotConfiguration @botParams

Start-PoshBot -Configuration $myBotConfig
```
