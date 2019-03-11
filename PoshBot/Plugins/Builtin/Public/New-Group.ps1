
function New-Group {
    <#
    .SYNOPSIS
        Create a new group.
    .PARAMETER Name
        The name of one or more groups to create.
    .PARAMETER Description
        A short description for the group.
    .EXAMPLE
        !new-group servicedesk 'Service desk users'

        Create a new group called [sevicedesk].
    .EXAMPLE
        !new-group -name foo, bar, baz

        Create three new groups in one command
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
        [string[]]$Name,

        [parameter(Position = 1)]
        [string]$Description
    )

    $notCreated = @()
    foreach ($groupName in $Name) {
        if (-not ($Bot.RoleManager.GetGroup($groupName))) {
            # Create group
            $group = [Group]::new($groupName, $Bot.Logger)
            if ($PSBoundParameters.ContainsKey('Description')) {
                $group.Description = $Description
            }
            $Bot.RoleManager.AddGroup($group)
            if (-not ($Bot.RoleManager.GetGroup($groupName))) {
                $notCreated += $groupName
            }
        } else {
            New-PoshBotCardResponse -Type Warning -Text "Group [$groupName] already exists" -ThumbnailUrl $thumb.warning
        }
    }

    if ($notCreated.Count -eq 0) {
        if ($Name.Count -gt 1) {
            $successMessage = 'Groups [{0}] created.' -f ($Name -join ', ')
        } else {
            $successMessage = "Group [$Name] created"
        }
        New-PoshBotCardResponse -Type Normal -Text $successMessage -ThumbnailUrl $thumb.success
    } else {
        if ($notCreated.Count -gt 1) {
            $errMsg = "Groups [{0}] could not be created. Check logs for more information." -f ($notCreated -join ', ')
        } else {
            $errMsg = "Group [$notCreated] could not be created. Check logs for more information."
        }
        New-PoshBotCardResponse -Type Warning -Text $errMsg -ThumbnailUrl $thumb.warning
    }
}
