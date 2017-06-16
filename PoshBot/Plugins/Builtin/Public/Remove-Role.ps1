
function Remove-Role {
    <#
    .SYNOPSIS
        Remove a role.
    .PARAMETER Name
        The name of the role to remove.
    .EXAMPLE
        !remove-role itsm-modify
    #>
    [PoshBot.BotCommand(
        Aliases = ('rr', 'remove-role'),
        Permissions = 'manage-roles'
    )]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Mandatory, Position = 0)]
        [string]$Name
    )

    if ($r = $Bot.RoleManager.GetRole($Name)) {
        try {
            $Bot.RoleManager.RemoveRole($r)
            New-PoshBotCardResponse -Type Normal -Text "Role [$Name] removed" -ThumbnailUrl $thumb.success
        } catch {
            New-PoshBotCardResponse -Type Error -Text "Failed to remove role [$Name]" -ThumbnailUrl $thumb.error
        }
    } else {
        New-PoshBotCardResponse -Type Warning -Text "Role [$Name] not found :(" -Title 'Rut row' -ThumbnailUrl $thumb.rutrow
    }
}
