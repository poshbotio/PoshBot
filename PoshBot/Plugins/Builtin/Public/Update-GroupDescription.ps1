
function Update-GroupDescription {
    <#
    .SYNOPSIS
        Update the description for a group.
    .PARAMETER Name
        The name of the group to update.
    .PARAMETER Description
        The new description for the group.
    .EXAMPLE
        !update-groupdescription servicedesk 'All Service Desk users'
    #>
    [PoshBot.BotCommand(
        Permissions = 'manage-groups'
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

    if ($g = $Bot.RoleManager.GetGroup($Name)) {
        try {
            $Bot.RoleManager.UpdateGroupDescription($Name, $Description)
            New-PoshBotCardResponse -Type Normal -Text "Group [$Name] description is now [$Description]" -ThumbnailUrl $thumb.success
        } catch {
            New-PoshBotCardResponse -Type Error -Text "Failed to update group [$Name]" -ThumbnailUrl $thumb.error
        }
    } else {
        New-PoshBotCardResponse -Type Warning -Text "Group [$Name] not found :(" -Title 'Rut row' -ThumbnailUrl $thumb.rutrow
    }
}
