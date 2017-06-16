
function New-Permission {
    <#
    .SYNOPSIS
        Creates a new adhoc permission associated with a plugin.
    .PARAMETER Name
        The name of the new permission to create.
    .PARAMETER Plugin
        The name of the plugin in which to associate the permission to.
    .PARAMETER Description
        The description for the new permission.
    .EXAMPLE
        !new-permission --name read --plugin myplugin --description 'Execute all read commands'

        Create the [read] permission in the [myplugin] plugin.
    #>
    [PoshBot.BotCommand(Permissions = 'manage-permissions')]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Mandatory, Position = 0)]
        [string]$Name,

        [parameter(Mandatory, Position = 1)]
        [string]$Plugin,

        [parameter(Position = 2)]
        [string]$Description
    )

    if ($pluginVersions = $Bot.PluginManager.Plugins[$Plugin]) {

        # Get the latest version of the the plugin
        $latestPluginVersion = @($pluginVersions.Keys | Sort-Object -Descending)[0]

        # Create the adhoc permission
        $permission = [Permission]::New($Name, $Plugin)
        $permission.Adhoc = $true
        if ($PSBoundParameters.ContainsKey('Description')) {
            $permission.Description = $Description
        }

        if ($pv = $pluginVersions[$latestPluginVersion]) {
            # Assign permission to plugin and add to Role Manager
            $Bot.RoleManager.AddPermission($permission)
            $pv.AddPermission($permission)
            $Bot.PluginManager.Savestate()

            if ($p = $Bot.RoleManager.GetPermission($permission.ToString())) {
                New-PoshBotCardResponse -Type Normal -Text "Permission [$($permission.ToString())] created." -ThumbnailUrl $thumb.success
            } else {
                New-PoshBotCardResponse -Type Warning -Text "Permission [$($permission.ToString())] could not be created. Check logs for more information." -ThumbnailUrl $thumb.warning
            }
        } else {
            New-PoshBotCardResponse -Type Warning -Text "Unable to get latest version of plugin [$Plugin]."
        }
    } else {
        New-PoshBotCardResponse -Type Warning -Text "Plugin [$Plugin] not found."
    }
}
