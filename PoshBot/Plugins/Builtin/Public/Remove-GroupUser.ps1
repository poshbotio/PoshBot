
function Remove-GroupUser {
    <#
    .SYNOPSIS
        Remove a user from a group.
    .PARAMETER Group
        The name of the group to remove a user from.
    .PARAMETER User
        The name of the user to remove from a group.
    .EXAMPLE
        !remove-groupuser --group admins --user johndoe
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
        [string]$User
    )

    if ($g = $Bot.RoleManager.GetGroup($Group)) {
        if ($userId = $Bot.RoleManager.ResolveUserToId($User)) {
            try {
                $bot.RoleManager.RemoveUserFromGroup($userId, $Group)
                New-PoshBotCardResponse -Type Normal -Text "User [$User] removed from group [$Group]." -ThumbnailUrl $thumb.success
            } catch {
                New-PoshBotCardResponse -Type Error -Text "Failed to remove [$User] from group [$Group]" -ThumbnailUrl $thumb.error
            }
        } else {
            New-PoshBotCardResponse -Type Warning -Text "User [$User] not found :(" -Title 'Rut row' -ThumbnailUrl $thumb.rutrow
        }
    } else {
        New-PoshBotCardResponse -Type Warning -Text "Group [$Group] not found :(" -Title 'Rut row' -ThumbnailUrl $thumb.rutrow
    }
}
