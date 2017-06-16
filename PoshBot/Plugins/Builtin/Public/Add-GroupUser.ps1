
function Add-GroupUser {
    <#
    .SYNOPSIS
        Add a user to a group.
    .PARAMETER Group
        The name of the group to add a user to.
    .PARAMETER User
        The name of the user to add to a group.
    .EXAMPLE
        !add-groupuser --group admins --user johndoe
    #>
    [PoshBot.BotCommand(Permissions = 'manage-groups')]
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
        # Resolve username to user id
        if ($userId = $Bot.RoleManager.ResolveUserToId($User)) {
            try {
                $bot.RoleManager.AddUserToGroup($userId, $Group)
                New-PoshBotCardResponse -Type Normal -Text "User [$User] added to group [$Group]." -ThumbnailUrl $thumb.success
            } catch {
                New-PoshBotCardResponse -Type Error -Text "Failed to add [$User] to group [$Group]" -ThumbnailUrl $thumb.error
            }
        } else {
            New-PoshBotCardResponse -Type Warning -Text "User [$User] not found :(" -Title 'Rut row' -ThumbnailUrl $thumb.rutrow
        }
    } else {
        New-PoshBotCardResponse -Type Warning -Text "Group [$Group] not found :(" -Title 'Rut row' -ThumbnailUrl $thumb.rutrow
    }
}
