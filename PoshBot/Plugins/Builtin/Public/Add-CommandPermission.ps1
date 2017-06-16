
function Add-CommandPermission {
    <#
    .SYNOPSIS
        Adds a permission to a command.
    .PARAMETER Command
        The fully qualified command name [pluginname:commandname] to add the permission to.
    .PARAMETER Permission
        The fully qualified permission name [pluginname:permissionname] to add to the command.
    .EXAMPLE
        !add-commandpermission --command myplugin:mycommand --permission myplugin:read

        Add the permission [myplugin:read] to the [myplugin:mycommand] command.
    #>
    [PoshBot.BotCommand(Permissions = 'manage-permissions')]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Mandatory, Position = 0)]
        [ValidatePattern('^.+:.+')]
        [Alias('Name')]
        [string]$Command,

        [parameter(Mandatory, Position = 1)]
        [ValidatePattern('^.+:.+')]
        [string]$Permission
    )

    if ($c = $Bot.PluginManager.Commands[$Command]) {
        if ($p = $Bot.RoleManager.Permissions[$Permission]) {

            $c.AddPermission($p)
            $Bot.PluginManager.SaveState()

            New-PoshBotCardResponse -Type Normal -Text "Permission [$Permission] added to command [$Command]." -ThumbnailUrl $thumb.success
        } else {
            New-PoshBotCardResponse -Type Warning -Text "Permission [$Permission] not found."
        }
    } else {
        New-PoshBotCardResponse -Type Warning -Text "Command [$Command] not found."
    }
}
