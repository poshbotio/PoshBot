
function Get-Role {
    <#
    .SYNOPSIS
        Show details about bot roles.
    .PARAMETER Name
        The name of the role to get.
    .EXAMPLE
        !get-role admin

        Get the [admin] role.
    #>
    [PoshBot.BotCommand(
        Aliases = ('gr', 'getrole'),
        Permissions = 'view-role'
    )]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Position = 0)]
        [string]$Name
    )

    if ($PSBoundParameters.ContainsKey('Name')) {
        $r = $Bot.RoleManager.GetRole($Name)
        if (-not $r) {
            New-PoshBotCardResponse -Type Warning -Text "Role [$Name] not found :(" -Title 'Rut row' -ThumbnailUrl $thumb.rutrow
        } else {
            $msg = [string]::Empty
            $msg += "`nDescription: $($r.Description)"
            $msg += "`nPermissions:`n$($r.Permissions.Keys | Format-List | Out-String)"
            New-PoshBotCardResponse -Type Normal -Title "Details for role [$Name]" -Text $msg
        }
    } else {
        $roles = foreach ($key in ($Bot.RoleManager.Roles.Keys | Sort-Object)) {
            [pscustomobject][ordered]@{
                Name = $key
                Description = $Bot.RoleManager.Roles[$key].Description
                Permissions = $Bot.RoleManager.Roles[$key].Permissions.Keys
            }
        }
        New-PoshBotCardResponse -Type Normal -Text ($roles | Format-List | Out-String)
    }
}
