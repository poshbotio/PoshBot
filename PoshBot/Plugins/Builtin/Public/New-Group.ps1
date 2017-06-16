
function New-Group {
    <#
    .SYNOPSIS
        Create a new group.
    .PARAMETER Name
        The name of the group to create.
    .PARAMETER Description
        A short description for the group.
    .EXAMPLE
        !new-group servicedesk 'Service desk users'

        Create a new group called [sevicedesk].
    #>
    [PoshBot.BotCommand(
        Aliases = ('ng', 'newgroup'),
        Permissions = 'manage-groups'
    )]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Mandatory, Position = 0)]
        [string]$Name,

        [parameter(Position = 1)]
        [string]$Description
    )

    $group = [Group]::New($Name)
    if ($PSBoundParameters.ContainsKey('Description')) {
        $group.Description = $Description
    }

    $Bot.RoleManager.AddGroup($group)
    if ($g = $Bot.RoleManager.GetGroup($Name)) {
        New-PoshBotCardResponse -Type Normal -Text "Group [$Name] created." -ThumbnailUrl $thumb.success
    } else {
        New-PoshBotCardResponse -Type Warning -Text "Group [$Name] could not be created. Check logs for more information." -ThumbnailUrl $thumb.warning
    }
}
