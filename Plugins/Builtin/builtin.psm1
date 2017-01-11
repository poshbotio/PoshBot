
function Help {
    <#
    .SYNOPSIS
        List bot commands
    .EXAMPLE
        !help mycommand
    #>
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [string]$Filter
    )

    #Write-Output ($bot | format-list | out-string)

    $availableCommands = New-Object System.Collections.ArrayList
    foreach ($pluginKey in $Bot.PluginManager.Plugins.Keys) {
        $plugin = $Bot.PluginManager.Plugins[$pluginKey]
        foreach ($commandKey in $plugin.Commands.Keys) {
            $command = $plugin.Commands[$commandKey]
            $x = [pscustomobject][ordered]@{
                Command = "$pluginKey`:$CommandKey"
                #Plugin = $pluginKey
                #Name = $commandKey
                Description = $command.Description
                HelpText = $command.HelpText
            }
            $availableCommands.Add($x) | Out-Null
        }
    }

    # If we asked for help about a particular plugin or command, filter on it
    if ($PSBoundParameters.ContainsKey('Filter')) {
        $availableCommands = $availableCommands.Where({$_.Command -like "*$Filter*"})
    }

    Write-Output ($availableCommands | Format-Table -AutoSize | Out-String -Width 200)
}

function Status {
    <#
    .SYNOPSIS
        Get Bot status
    .EXAMPLE
        !status
    #>
    param(
        [parameter(Mandatory)]
        $Bot
    )

    if ($Bot._Stopwatch.IsRunning) {
        $uptime = $Bot._Stopwatch.Elapsed.ToString()
    } else {
        $uptime = $null
    }
    $hash = [ordered]@{
        Version = '1.0.0'
        Uptime = $uptime
        Plugins = $Bot.PluginManager.Plugins.Count
        Commands = $Bot.PluginManager.Commands.Count
    }

    $status = [pscustomobject]$hash
    $status
}

function Role-List {
    <#
    .SYNOPSIS
        Get all roles
    .EXAMPLE
        !role list
    .ROLE
        Admin
        RoleAdmin
    #>
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot
    )

    $roles = foreach ($key in ($Bot.RoleManager.Roles.Keys | Sort-Object)) {
        [pscustomobject][ordered]@{
            Name = $key
            Description =$Bot.RoleManager.Roles[$key].Description
        }
    }
    Write-Output ($roles | Format-Table -AutoSize | Out-String -Width 150)
}

function Role-Show {
    <#
    .SYNOPSIS
        Show details about a role
    .EXAMPLE
        !role show --role <rolename>
    .ROLE
        Admin
        RoleAdmin
    #>
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Mandatory)]
        [string]$Role
    )

    $r = $Bot.RoleManager.GetRole($Role)
    if (-not $r) {
        Write-Error "Role [$Role] not found :("
        return
    }
    $roleMapping = $Bot.RoleManager.RoleUserMapping[$Role]
    $members = New-Object System.Collections.ArrayList
    if ($roleMapping) {
        $roleMapping.GetEnumerator() | ForEach-Object {
            $user = $bot.Backend.GetUser($_.Value)
            if ($user) {
                $m = [pscustomobject][ordered]@{
                    Nickname = $user.Nickname
                    FullName = $user.FullName
                }
                $members.Add($m) | Out-Null
            }
        }
    }

    Write-Output "Role details for [$Role]"
    Write-Output "Description: $($r.Description)"
    Write-Output "Members:`n$($Members | Format-Table | Out-String)"
}

function Role-AddUser {
    <#
    .SYNOPSIS
        Add a user to a role
    .EXAMPLE
        !role adduser --role <rolename> --user <username>
    .ROLE
        Admin
        RoleAdmin
    #>
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Mandatory)]
        [string]$Role,

        [parameter(Mandatory)]
        [string]$User
    )

    # Validate role and username
    $id = $Bot.RoleManager.ResolveUserToId($User)
    if (-not $id) {
        throw "Username [$User] was not found."
    }
    $r = $Bot.RoleManager.GetRole($Role)
    if (-not $r) {
        throw "Username [$User] was not found."
    }

    try {
        $Bot.RoleManager.AddUserToRole($id, $Role)
        Write-Output "OK, user [$User] added to role [$Role]"
    } catch {
        throw $_
    }
}

function Plugin-List {
    <#
    .SYNOPSIS
        Get all installed plugins
    .EXAMPLE
        !plugin list
    .ROLE
        Admin
        PluginAdmin
    #>
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot
    )

    $plugins = foreach ($key in ($Bot.PluginManager.Plugins.Keys | Sort-Object)) {
        $plugin = $Bot.PluginManager.Plugins[$key]
        [pscustomobject][ordered]@{
            Name = $key
            Commands = $plugin.Commands.Keys
            Roles = $plugin.Roles.Keys
            Enabled = $plugin.Enabled
        }
    }
    Write-Output ($plugins | Format-List | Out-String -Width 150)
}

function Plugin-Show {
    <#
    .SYNOPSIS
        Get the details of a specific plugin
    .EXAMPLE
        !plugin show --plugin <plugin name>
    .ROLE
        Admin
        PluginAdmin
    #>
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Mandatory)]
        [string]$Plugin
    )

    $p = $Bot.PluginManager.Plugins[$Plugin]
    if ($p) {
        $r = [pscustomobject]@{
            Name = $P.Name
            Enabled = $p.Enabled
            CommandCount = $p.Commands.Count
            Roles = $p.Roles.Keys
            Commands = $p.Commands
        }

        Write-Output "Name: $($r.Name)"
        Write-Output "Enabled: $($r.Enabled)"
        Write-Output "CommandCount: $($r.CommandCount)"
        Write-Output "Roles: `n$($r.Roles | Format-List | Out-String)"
        $fields = @(
            @{
                Expression = {$_.Name}
                Label = 'Name'
            }
            @{
                Expression = {$_.Value.Description}
                Label = 'Description'
            }
            @{
                Expression = {$_.Value.HelpText}
                Label = 'Trigger'
            }
        )
        Write-Output "Commands: `n$($r.Commands.GetEnumerator() | Select-Object -Property $fields | Format-Table -AutoSize | Out-String)"
    } else {
        Write-Warning "Plugin [$Plugin] not found."
    }
}

function About {
    [cmdletbinding()]
    param(
        $Bot
    )

    $path = "$PSScriptRoot/../../PoshBot.psd1"
    #$manifest = Test-ModuleManifest -Path $path -Verbose:$false
    $manifest = Import-PowerShellDataFile -Path $path
    $ver = $manifest.ModuleVersion

    $msg = @"
PoshBot v$ver
$($manifest.CopyRight)

https://github.com/devblackops/PoshBot
"@
    $msg
}

Export-ModuleMember -Function *
