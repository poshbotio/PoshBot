
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

    # Remove group(s)
    foreach ($groupName in $Name) {
        if ($g = $Bot.RoleManager.GetGroup($groupName)) {
            $Bot.RoleManager.RemoveGroup($g)
            if ($g = $Bot.RoleManager.GetGroup($groupName)) {
                $failedToRemove += $groupName
            } else {
                $removed += $groupName
            }
        } else {
            $notFound += $groupName
        }
    }

    # Send success messages
    if ($removed.Count -ge 1) {
        if ($removed.Count -gt 1) {
            $successMessage = 'Groups [{0}] removed.' -f ($removed -join ', ')
        } else {
            $successMessage = "Group [$removed] removed"
        }
        $response.Type = 'Normal'
        $response.Text = $successMessage
        $response.Title = $null
        $response.ThumbnailUrl = $thumb.success
    }

    # Send warning messages
    if ($notFound.Count -ge 1) {
        if ($notFound.Count -gt 1) {
            $warningMessage = 'Groups [{0}] not found :(' -f ($removed -join ', ')
        } else {
            $warningMessage = "Group [$notFound] not found :("
        }
        $response.Type = 'Warning'
        $response.Text = $warningMessage
        $response.Title = $null
        $response.ThumbnailUrl = $thumb.rutrow
    }

    # Send failure messages
    if ($failedToRemove.Count -ge 1) {
        if ($failedToRemove.Count -gt 1) {
            $errMsg = "Groups [{0}] could not be removed. Check logs for more information." -f ($failedToRemove -join ', ')
        } else {
            $errMsg = "Group [$failedToRemove] could not be created. Check logs for more information."
        }
        $response.Type = 'Error'
        $response.Text = $errMsg
        $response.Title = $null
        $response.ThumbnailUrl = $thumb.error
    }

    New-PoshBotCardResponse @response
}
