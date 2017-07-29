
function New-Role {
    <#
    .SYNOPSIS
        Create a new role.
    .PARAMETER Name
        The name of the new role to create.
    .PARAMETER Description
        The description for the new role.
    .EXAMPLE
        !rew-role 'itsm-modify' 'Can modify items in ITSM tool'
    #>
    [PoshBot.BotCommand(
        Aliases = ('nr', 'newrole'),
        Permissions = 'manage-roles'
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

    $role = [Role]::New($Name, $Bot.Logger)
    if ($PSBoundParameters.ContainsKey('Description')) {
        $role.Description = $Description
    }

    $Bot.RoleManager.AddRole($role)
    if ($g = $Bot.RoleManager.GetRole($Name)) {
        New-PoshBotCardResponse -Type Normal -Text "Role [$Name] created." -ThumbnailUrl $thumb.success
    } else {
        New-PoshBotCardResponse -Type Warning -Text "Role [$Name] could not be created. Check logs for more information." -ThumbnailUrl $thumb.warning
    }
}
