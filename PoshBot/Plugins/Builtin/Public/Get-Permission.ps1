
function Get-Permission {
    <#
    .SYNOPSIS
        Show details about bot permissions.
    .PARAMETER Name
        The name of the permission to get.
    .EXAMPLE
        !get-permission

        Get a list of all permissions.
    .EXAMPLE
        !get-permission --name builtin:manage-groups

        Get details about the [builtin:manage-groups] permission.
    #>
    [PoshBot.BotCommand(
        Aliases = ('getpermission'),
        Permissions = 'view'
    )]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Position = 0)]
        [string]$Name
    )

    if ($PSBoundParameters.ContainsKey('Name')) {
        if ($p = $Bot.RoleManager.GetPermission($Name)) {
            $o = [pscustomobject][ordered]@{
                FullName = $p.ToString()
                Name = $p.Name
                Plugin = $p.Plugin
                Description = $p.Description
            }
            New-PoshBotCardResponse -Type Normal -Text ($o | Format-List | Out-String)
        } else {
            New-PoshBotCardResponse -Type Error -Text "Permission [$Name] not found :(" -Title 'Rut row' -ThumbnailUrl $thumb.rutrow
        }
    } else {
        $permissions = foreach ($key in ($Bot.RoleManager.Permissions.Keys | Sort-Object)) {
            [pscustomobject][ordered]@{
                Name = $key
                Description = $Bot.RoleManager.Permissions[$key].Description
            }
        }
        New-PoshBotCardResponse -Type Normal -Text ($permissions | Format-Table -AutoSize | Out-String)
    }
}
