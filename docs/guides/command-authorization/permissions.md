
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
