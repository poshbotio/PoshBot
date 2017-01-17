
function New-PoshBotAccessFilter {
    [cmdletbinding()]
    param(
        [string[]]$AllowRoles = @(),

        [string[]]$DenyRoles = @(),

        [string[]]$AllowUsers = @(),

        [string[]]$DenyUsers = @()

        # [string[]]$AllowRooms = @(),

        # [string[]]$DenyRooms = @(),

        # [bool]$AllowPrivate = $true,

        # [bool]$AllowChannel = $true
    )

    $af = [AccessFilter]::new()
    $AllowRoles | ForEach-Object {
        if (-not $af.AllowRoles.ContainsKey($_)) {
            $af.AllowRoles.Add($_, $null)
        }
    }
    $DenyRoles | ForEach-Object {
        if (-not $af.DenyRoles.ContainsKey($_)) {
            $af.DenyRoles.Add($_, $null)
        }
    }
    $AllowUsers | ForEach-Object {
        if (-not $af.AllowUsers.ContainsKey($_)) {
            $af.AllowUsers.Add($_, $null)
        }
    }
    $DenyUsers | ForEach-Object {
        if (-not $af.DenyUsers.ContainsKey($_)) {
            $af.DenyUsers.Add($_, $null)
        }
    }
    # $AllowRooms | ForEach-Object {
    #     if (-not $af.AllowRooms.ContainsKey($_)) {
    #         $af.AllowRooms.Add($_, $null)
    #     }
    # }
    # $DenyRooms | ForEach-Object {
    #     if (-not $af.DenyRooms.ContainsKey($_)) {
    #         $af.DenyRooms.Add($_, $null)
    #     }
    # }
    # $af.AllowPrivate = $AllowPrivate
    # $af.AllowChannel = $AllowChannel

    return $af
}
