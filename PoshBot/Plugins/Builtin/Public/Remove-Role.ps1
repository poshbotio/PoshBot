
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
        [string[]]$Name
    )

    $removed = @()
    $notFound = @()
    $failedToRemove = @()
    $response = @{
        Type         = 'Normal'
        Text         = ''
        Title        = $null
        ThumbnailUrl = $thumb.success
    }

    # Remove role(s)
    foreach ($roleName in $Name) {
        if ($r = $Bot.RoleManager.GetRole($roleName)) {
            $Bot.RoleManager.RemoveRole($r)
            if ($r = $Bot.RoleManager.GetRole($roleName)) {
                $failedToRemove += $roleName
            } else {
                $removed += $roleName
            }
        } else {
            $notFound += $roleName
        }
    }

    # Send success messages
    if ($removed.Count -ge 1) {
        if ($removed.Count -gt 1) {
            $successMessage = 'Roles [{0}] removed.' -f ($removed -join ', ')
        } else {
            $successMessage = "Role [$removed] removed"
        }
        $response.Type = 'Normal'
        $response.Text = $successMessage
        $response.Title = $null
        $response.ThumbnailUrl = $thumb.success
    }

    # Send warning messages
    if ($notFound.Count -ge 1) {
        if ($notFound.Count -gt 1) {
            $warningMessage = 'Roles [{0}] not found :(' -f ($removed -join ', ')
        } else {
            $warningMessage = "Role [$notFound] not found :("
        }
        $response.Type = 'Warning'
        $response.Text = $warningMessage
        $response.Title = $null
        $response.ThumbnailUrl = $thumb.rutrow
    }

    # Send failure messages
    if ($failedToRemove.Count -ge 1) {
        if ($failedToRemove.Count -gt 1) {
            $errMsg = "Roles [{0}] could not be removed. Check logs for more information." -f ($failedToRemove -join ', ')
        } else {
            $errMsg = "Role [$failedToRemove] could not be created. Check logs for more information."
        }
        $response.Type = 'Error'
        $response.Text = $errMsg
        $response.Title = $null
        $response.ThumbnailUrl = $thumb.error
    }

    New-PoshBotCardResponse @response
}
