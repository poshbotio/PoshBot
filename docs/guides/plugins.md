
# Plugins

A plugin is a collection of related commands.
PoshBot uses PowerShell modules as the mechanism to manage commands.

> So what is a plugin? It is a normal PowerShell module. That's really all it is :)

All exported functions from the powershell module become available in PoshBot when the module (plugin) is loaded.
Using modules enables some great features for free.

* Versioning

  Multiple PoshBot plugins can be loaded at one time.

* Distribution

  Modules are distributed on the [PowerShell Gallery](https://www.powershellgallery.com/) or on your own internal repositories.

* Familiarity

  Most people writing PowerShell for any length of time will be familar with writing PowerShell modules.
  Writing PoshBot plugins is no different as they are just modules.

Even though PoshBot plugins are normal PowerShell modules, there is some PoshBot-specific metadata that can be included in the module to tell PoshBot how to secure the commands contained within.

## Permissions

A PoshBot command can have one or more permissions attached to them.
A permission is the base unit used for security.
Permissions are nothing more than tokens that are applied to commands.
These permissions are then collected into **roles**.
Permissions available in a plugin are defined in the **PrivateData** section of the PowerShell module manifest for the plugin.
When specifying the permissions inside the module manifest, an array of strings and/or hashtables can be used.
When using a hashtable, a **Name** key must be used.
The **Description** key is optional but recommended.

### MyPlugin.psd1

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
How will PoshBot tell them apart?
The answer is that PoshBot *namespaces* permissions.
The plugin (module) above is called `MyPlugin`.
This would make the fully qualified permission name `MyPlugin:Read` or `MyPlugin:Write`.
This fully qualified name is what is used throughout PoshBot.
Another plugin called `Network` may also include `Read` and `Write` permissions but the fully qualified name for these permissions would be `Network:Read` and `Network:Write` respectively.
With namespaces, plugin authors don't need to worry about naming conflicts between plugins.
