
function Remove-Group {
    <#
    .SYNOPSIS
        Remove a group.
    .PARAMETER Name
        The name of the group to remove.
    .EXAMPLE
        !remove-group servicedesk

        Remove the [servicedesk] group.
    #>
    [PoshBot.BotCommand(
        Aliases = ('rg', 'removegroup'),
        Permissions = 'manage-groups'
    )]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Mandatory, Position = 0)]
        [string]$Name
    )

    if ($g = $Bot.RoleManager.GetGroup($Name)) {
        try {
            $Bot.RoleManager.RemoveGroup($g)
            New-PoshBotCardResponse -Type Normal -Text "Group [$Name] removed" -ThumbnailUrl $thumb.success
        } catch {
            New-PoshBotCardResponse -Type Error -Text "Failed to remove group [$Name]" -ThumbnailUrl $thumb.error
        }
    } else {
        New-PoshBotCardResponse -Type Warning -Text "Group [$Name] not found :(" -Title 'Rut row' -ThumbnailUrl $thumb.rutrow
    }
}
