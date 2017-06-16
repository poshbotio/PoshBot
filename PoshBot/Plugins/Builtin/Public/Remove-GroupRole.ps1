
function Remove-GroupRole {
    <#
    .SYNOPSIS
        Remove a role from a group.
    .PARAMETER Group
        The name of the group to remove a role from.
    .PARAMETER Role
        The name of the role to remove from a group.
    .EXAMPLE
        !remove-grouprole --group servicedesk --role itsm-modify
    #>
    [PoshBot.BotCommand(
        Permissions = 'manage-groups'
    )]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Mandatory, Position = 0)]
        [string]$Group,

        [parameter(Mandatory, Position = 1)]
        [string]$Role
    )

    if ($g = $Bot.RoleManager.GetGroup($Group)) {
        if ($r = $Bot.RoleManager.GetRole($Role)) {
            try {
                $bot.RoleManager.RemoveRoleFromGroup($Role, $Group)
                New-PoshBotCardResponse -Type Normal -Text "Role [$Role] removed from group [$Group]." -ThumbnailUrl $thumb.success
            } catch {
                New-PoshBotCardResponse -Type Error -Text "Failed to remove [$Role] from group [$Group]" -ThumbnailUrl $thumb.error
            }
        } else {
            New-PoshBotCardResponse -Type Warning -Text "Role [$Role] not found :(" -Title 'Rut row' -ThumbnailUrl $thumb.rutrow
        }
    } else {
        New-PoshBotCardResponse -Type Warning -Text "Group [$Group] not found :(" -Title 'Rut row' -ThumbnailUrl $thumb.rutrow
    }
}
