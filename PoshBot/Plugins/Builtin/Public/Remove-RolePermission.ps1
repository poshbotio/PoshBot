
function Remove-RolePermission {
    <#
    .SYNOPSIS
        Remove a permission from a role.
    .PARAMETER Role
        The name of the role to remove a permission from.
    .PARAMETER Permission
        The name of the permission to remove from the role.
    .EXAMPLE
        !remove-rolepermission --role 'itsm-modify' --permission 'itsm:create-ticket'

        Remove the [itsm:create-ticket] permission from the [itsm-modify] role.
    #>
    [PoshBot.BotCommand(
        Permissions = 'manage-roles'
    )]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Mandatory, Position = 0)]
        [string]$Role,

        [parameter(Mandatory, Position = 1)]
        [string]$Permission
    )

    if ($r = $Bot.RoleManager.GetRole($Role)) {
        if ($p = $Bot.RoleManager.Permissions[$Permission]) {
            try {
                $Bot.RoleManager.RemovePermissionFromRole($Permission, $Role)
                New-PoshBotCardResponse -Type Normal -Text "Permission [$Permission] removed from role [$role]." -ThumbnailUrl $thumb.success
            } catch {
                New-PoshBotCardResponse -Type Error -Text "Failed to remove [$Permission] from role [$role]" -ThumbnailUrl $thumb.error
            }
        } else {
            New-PoshBotCardResponse -Type Warning -Text "Permission [$Permission] not found :(" -Title 'Rut row' -ThumbnailUrl $thumb.rutrow
        }
    } else {
        New-PoshBotCardResponse -Type Warning -Text "Role [$Role] not found :(" -Title 'Rut row' -ThumbnailUrl $thumb.rutrow
    }
}
