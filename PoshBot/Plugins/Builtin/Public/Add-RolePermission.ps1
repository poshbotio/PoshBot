
function Add-RolePermission {
    <#
    .SYNOPSIS
        Add a permission to a role.
    .PARAMETER Role
        The name of the role to add a permission to.
    .PARAMETER Permission
        The name of the permission to add to the role.
    .EXAMPLE
        !add-rolepermission --role 'itsm-modify' --permission 'itsm:create-ticket'

        Add the [itsm:create-ticket] permission to the [itsm-modify] role.
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
                $Bot.RoleManager.AddPermissionToRole($Permission, $Role)
                New-PoshBotCardResponse -Type Normal -Text "Permission [$Permission] added to role [$Role]." -ThumbnailUrl $thumb.success
            } catch {
                New-PoshBotCardResponse -Type Error -Text "Failed to add [$Permission] to group [$Role]" -ThumbnailUrl $thumb.error
            }
        } else {
            New-PoshBotCardResponse -Type Warning -Text "Permission [$Permission] not found :(" -Title 'Rut row' -ThumbnailUrl $thumb.rutrow
        }
    } else {
        New-PoshBotCardResponse -Type Warning -Text "Role [$Role] not found :(" -Title 'Rut row' -ThumbnailUrl $thumb.rutrow
    }
}
