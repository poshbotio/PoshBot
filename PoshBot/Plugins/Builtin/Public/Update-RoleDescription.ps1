
function Update-RoleDescription {
    <#
    .SYNOPSIS
        Update a role description
    .PARAMETER Name
        The name of the role to update.
    .PARAMETER Description
        The new description for the role.
    .EXAMPLE
        !update-roledescription --name itsm-modify --description 'Can modify items in ITSM tool'
    #>
    [PoshBot.BotCommand(
        Permissions = 'manage-roles'
    )]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Mandatory, Position = 0)]
        [string]$Name,

        [parameter(Mandatory, Position = 1)]
        [string]$Description
    )

    if ($r = $Bot.RoleManager.GetRole($Name)) {
        try {
            $Bot.RoleManager.UpdateRoleDescription($Name, $Description)
            New-PoshBotCardResponse -Type Normal -Text "Role [$Name] description is now [$Description]" -ThumbnailUrl $thumb.success
        } catch {
            New-PoshBotCardResponse -Type Error -Text "Failed to update role [$Name]" -ThumbnailUrl $thumb.error
        }
    } else {
        New-PoshBotCardResponse -Type Warning -Text "Role [$Name] not found :(" -Title 'Rut row' -ThumbnailUrl $thumb.rutrow
    }
}
