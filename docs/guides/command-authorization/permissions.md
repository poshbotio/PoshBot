
# Permissions

A PoshBot command can have one or more permissions attached to them.
A permission is the base unit used for security.
Permissions are nothing more than tokens that are applied to commands.
These permissions are then collected into **roles**.
Permissions available in a plugin are defined in the **PrivateData** section of the PowerShell module manifest for the plugin.
When specifying the permissions inside the module manifest, an array of strings and/or hashtables can be used.
When using a hashtable, a **Name** key must be used.
The **Description** key is optional but recommended.

#### MyPlugin.psd1

```powershell
@{
    # Other properties omitted for brevity
    # ...
    #
    PrivateData = @{
        Permissions = @(
            'command1'
            'command2'
            @{
                Name = 'Read'
                Description = 'Can execute all Get-* commands of the plugin'
            }
            @{
                Name = 'Write'
                Description = 'Can execute all New-*, Set-*, and Remove-* commands of the plugin'
            }
        )
    }
}
```

When defining permissions within the module manifest, you only need to specify a name like **Read**.
But what if another plugin also has a permission with the name **Read**?
How will you tell them apart?
The answer is that PoshBot *namespaces* permissions.
The plugin (module) above is called `MyPlugin`.
This would make the fully qualified permission name `MyPlugin:Read` or `MyPlugin:Write`.
This fully qualified name is what is used throughout PoshBot.
Another plugin called `Network` may also include `Read` and `Write` permissions but the fully qualified name for these permissions would be `Network:Read` and `Network:Write` respectively.
With namespaces, plugin authors don't need to worry about naming conflicts between plugins.

## Association Permissions with Commands

Once permissions are defined in the module manifest, you can declare what permissions are needed in order to execute your commands.
PoshBot provides a **custom attribute** called `[PoshBot.BotCommand()]` that you can decorate your functions with.
One of the things this attribute defines is the permission(s) needed by the user to execute this command.

#### [PoshBot.BotCommand()] properties

| Property       | Type     | Description |
| :--------------|:---------|:------------|
| CommandName    | string   | The name of the bot command. Default is the function name
| TriggerType    | string   | The type of trigger. Values: `Command`, `Regex`, `Event`
| HideFromHelp   | bool     | Whether to hide the command when the !help command is used. Default is `$false`
| Regex          | string   | A regex string to match the command against. Only valid when TriggerType is `Regex`
| MessageType    | string   | Type of message this command is triggered against. Only valid when TriggerType is `Event`
| MessageSubtype | string   | Subtype of message this command is triggered against. Only valid when TriggerType is `Event`
| Permissions    | string[] | String array of permissions to apply to the command. Only users with the given permissions are allow to execute command

In order to associate one or more permissions with a command, you attach the `[PoshBot.BotCommand()]` attribute to the function similarly to the `[cmdletbinding()]` attribute.
By specifying the `Permissions` property, you are declaring that the user must have **one of** these permissions in order to execute the command.

> When declaring permissions on the function, the fully qualified permission name `<myplugin>:<permissionname>` is not needed.
> Only the permission name is needed. Internally, PoshBot will store the permission fully qualified.

```powershell
function New-Thing {
    [PoshBot.BotCommand(Permissions = 'create-things')]
    [cmdletbinding()]
    param(
        [string]$Name
    )

    ...
}

```