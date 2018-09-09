
function New-Role {
    <#
    .SYNOPSIS
        Create a new role.
    .PARAMETER Name
        The name of one or more roles to create.
    .PARAMETER Description
        The description for the new role.
    .EXAMPLE
        !rew-role 'itsm-modify' 'Can modify items in ITSM tool'

        Create a new role called called [itsm-modify].
    .EXAMPLE
        !new-role -name foo, bar, baz

        Create three new roles in one command.
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
        [string[]]$Name,

        [parameter(Position = 1)]
        [string]$Description
    )

    $notCreated = @()
    foreach ($roleName in $Name) {
        if (-not ($Bot.RoleManager.GetRole($roleName))) {
            # Create role
            $role = [Role]::New($roleName, $Bot.Logger)
            if ($PSBoundParameters.ContainsKey('Description')) {
                $role.Description = $Description
            }
            $Bot.RoleManager.AddRole($role)
            if (-not ($Bot.RoleManager.GetRole($roleName))) {
                $notCreated += $roleName
            }
        } else {
            New-PoshBotCardResponse -Type Warning -Text "Role [$roleName] already exists" -ThumbnailUrl $thumb.warning
        }
    }

    if ($notCreated.Count -eq 0) {
        if ($Name.Count -gt 1) {
            $successMessage = 'Roles [{0}] created.' -f ($Name -join ', ')
        } else {
            $successMessage = "Role [$Name] created"
        }
        New-PoshBotCardResponse -Type Normal -Text $successMessage -ThumbnailUrl $thumb.success
    } else {
        if ($notCreated.Count -gt 1) {
            $errMsg = "Roles [{0}] could not be created. Check logs for more information." -f ($notCreated -join ', ')
        } else {
            $errMsg = "Role [$notCreated] could not be created. Check logs for more information."
        }
        New-PoshBotCardResponse -Type Warning -Text $errMsg -ThumbnailUrl $thumb.warning
    }
}
