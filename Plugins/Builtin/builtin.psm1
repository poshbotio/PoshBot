
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

    if ($Filter) {
        New-PoshBotCardResponse -Type Normal -DM -Title "Help for [$Filter]" -Text ($availableCommands | Format-List | Out-String)
    } else {
        New-PoshBotCardResponse -Type Normal -DM -Text ($availableCommands | Format-List | Out-String)
    }
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
    #New-PoshBotCardResponse -Type Normal -Text ($status | Format-List | Out-String)
    New-PoshBotCardResponse -Type Normal -Fields $hash -Title 'PoshBot Status'
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
    New-PoshBotCardResponse -Type Normal -Text ($roles | Format-Table -AutoSize | Out-String -Width 150)
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
        New-PoshBotCardResponse -Type Error -Text "Role [$Role] not found :(" -Title 'Rut row' -ThumbnailUrl 'http://images4.fanpop.com/image/photos/17000000/Scooby-Doo-Where-Are-You-The-Original-Intro-scooby-doo-17020515-500-375.jpg'
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

    $msg = [string]::Empty
    $msg += "Role details for [$Role]"
    $msg += "`nDescription: $($r.Description)"
    $msg += "`nMembers:`n$($Members | Format-Table | Out-String)"
    New-PoshBotCardResponse -Type Normal -Text $msg
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
        New-PoshBotCardResponse -Type Normal -Text "OK, user [$User] added to role [$Role]"
    } catch {
        throw $_
    }
}

function Command-Show {
    <#
    .SYNOPSIS
        Show the details of a specific command
    .EXAMPLE
        !command show --name <command name>
    #>
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Mandatory)]
        [string]$Name
    )

    $commands = @($Bot.PluginManager.Commands.Keys | Where-Object {$_ -like "*$Name*" })

    if ($commands.Count -gt 0) {
        foreach ($key in $commands) {
            $command = $Bot.Pluginmanager.Commands[$key]
            $fields = [ordered]@{
                Name = $command.Name
                Description = $command.Description
                HelpText = $command.HelpText
                Enabled = $command.Enabled.ToString()
                AllowedRoles = $command.AccessFilter.AllowRoles.Keys  | Format-List | Out-String
                DeniedRoles = $command.AccessFilter.DenyRoles.Keys | Format-List | Out-String
            }
            New-PoshBotCardResponse -Type Normal -Title "Details for [$($command.Name)]" -Fields $fields
        }
    } else {
        New-PoshBotCardResponse -Type Warning -Text "Command [$Name] not found."
    }
}

function Plugin-List {
    <#
    .SYNOPSIS
        Get all installed plugins
    .EXAMPLE
        !plugin list
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
    New-PoshBotCardResponse -Type Normal -Text ($plugins | Format-List | Out-String -Width 150)
}

function Plugin-Show {
    <#
    .SYNOPSIS
        Get the details of a specific plugin
    .EXAMPLE
        !plugin show --plugin <plugin name>
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
        $properties = @(
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
                Label = 'Usage'
            }
        )
        $fields = [ordered]@{
            Title = $r.Name
            Enabled = $r.Enabled.ToString()
            CommandCount = $r.CommandCount
            Roles = $r.Roles | Format-List | Out-String
            #Commands = $r.Commands.GetEnumerator() | Select-Object -Property $properties | Format-List | Out-String
            Commands = $r.Commands.Keys | Format-List | Out-String
        }
        # $fields = @(
        #     @{
        #         title = 'Name'
        #         value = $r.Name
        #         short = $true
        #     }
        #     @{
        #         title = 'Enabled'
        #         value = $r.Enabled
        #         short = $true
        #     }
        #     @{
        #         title = 'CommandCount'
        #         value = $r.CommandCount
        #         short = $true
        #     }
        #     @{
        #         title = 'Roles'
        #         value = $r.Roles | Format-List | Out-String
        #         short = $false
        #     }
        # )

        $msg = [string]::Empty
        #$msg += "Name: $($r.Name)"
        #$msg += "`nEnabled: $($r.Enabled)"
        #$msg += "`nCommandCount: $($r.CommandCount)"
        #$msg += "`nRoles: `n$($r.Roles | Format-List | Out-String)"
        $properties = @(
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
                Label = 'Usage'
            }
        )
        $msg += "`nCommands: `n$($r.Commands.GetEnumerator() | Select-Object -Property $properties | Format-List | Out-String)"
        New-PoshBotCardResponse -Type Normal -Fields $fields
    } else {
        New-PoshBotCardResponse -Type Warning -Text "Plugin [$Plugin] not found."
    }
}

function Plugin-Install {
    <#
    .SYNOPSIS
        Install a new plugin
    .EXAMPLE
        !plugin install --plugin <plugin name>
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

    if ($Plugin -ne 'Builtin') {
        # Attempt to find the module in $env:PSModulePath or in the configurated repository
        $mod = Get-Module -Name $Plugin -ListAvailable
        if (-not $mod) {
            $onlineMod = Find-Module -Name $Plugin -Repository $bot.Configuration.PluginRepository -ErrorAction SilentlyContinue
            if ($onlineMod) {
                Install-Module -Name $Plugin -Repository $bot.Configuration.PluginRepository -Scope CurrentUser -ErrorAction Stop
                $mod = Get-Module -Name $Plugin -ListAvailable
            }
        }

        if ($mod) {
            try {
                $bot | Add-PoshBotPlugin -ModuleManifest $mod.Path -ErrorAction Stop
                $resp = Plugin-Show -Bot $bot -Plugin $Plugin
                if (-not ($resp | Get-Member -Name 'Title' -MemberType NoteProperty)) {
                    $resp | Add-Member -Name 'Title' -MemberType NoteProperty -Value $null
                }
                $resp.Title = "Plugin [$Plugin] successfully installed"
                return $resp
            } catch {
                return New-PoshBotCardResponse -Type Error -Text $_.Exception.Message -Title 'Rut row' -ThumbnailUrl 'http://images4.fanpop.com/image/photos/17000000/Scooby-Doo-Where-Are-You-The-Original-Intro-scooby-doo-17020515-500-375.jpg'
            }
        } else {
            return New-PoshBotCardResponse -Type Warning -Text "Plugin [$Plugin] not found in configured plugin directory [$($Bot.Configuration.PluginDirectory)] or repository [$($Bot.Configuration.PluginRepository)]" -ThumbnailUrl 'http://p1cdn05.thewrap.com/images/2015/06/don-draper-shrug.jpg'
        }
    } else {
        return New-PoshBotCardResponse -Type Warning -Text 'The builtin plugin is already... well... builtin :)' -Title 'Not gonna do it'
    }
}

function Plugin-Enable {
    <#
    .SYNOPSIS
        Enable a currently loaded plugin
    .EXAMPLE
        !plugin enable --plugin <plugin name>
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

    if ($Plugin -ne 'Builtin') {
        if ($p = $bot.PluginManager.Plugins[$Plugin]) {
            try {
                $bot.PluginManager.ActivatePlugin($p)
                #Write-Output "Plugin [$Plugin] activated. All commands in this plugin are now enabled."
                return New-PoshBotCardResponse -Type Normal -Text "Plugin [$Plugin] activated. All commands in this plugin are now enabled." -ThumbnailUrl 'https://www.streamsports.com/images/icon_green_check_256.png'
            } catch {
                #Write-Error $_
                return New-PoshBotCardResponse -Type Error -Text $_.Exception.Message -Title 'Rut row' -ThumbnailUrl 'http://images4.fanpop.com/image/photos/17000000/Scooby-Doo-Where-Are-You-The-Original-Intro-scooby-doo-17020515-500-375.jpg'
            }
        } else {
            #Write-Warning "Plugin [$Plugin] not found."
            return New-PoshBotCardResponse -Type Warning -Text "Plugin [$Plugin] not found." -ThumbnailUrl 'http://hairmomentum.com/wp-content/uploads/2016/07/warning.png'
        }
    } else {
        #Write-Output "Builtin plugins can't be disabled so no need to enable them."
        return New-PoshBotCardResponse -Type Normal -Text "Builtin plugins can't be disabled so no need to enable them." -Title 'Ya no'
    }
}

function Plugin-Disable {
    <#
    .SYNOPSIS
        Disable a currently loaded plugin
    .EXAMPLE
        !plugin disable --plugin <plugin name>
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

    if ($Plugin -ne 'Builtin') {
        if ($p = $bot.PluginManager.Plugins[$Plugin]) {
            try {
                $bot.PluginManager.DeactivatePlugin($p)
                #Write-Output "Plugin [$Plugin] deactivated. All commands in this plugin are now disabled."
                return New-PoshBotCardResponse -Type Normal -Text "Plugin [$Plugin] deactivated. All commands in this plugin are now disabled." -Title 'Plugin deactivated' -ThumbnailUrl 'https://www.streamsports.com/images/icon_green_check_256.png'
            } catch {
                #Write-Error $_
                return New-PoshBotCardResponse -Type Error -Text $_.Exception.Message -Title 'Rut row' -ThumbnailUrl 'http://images4.fanpop.com/image/photos/17000000/Scooby-Doo-Where-Are-You-The-Original-Intro-scooby-doo-17020515-500-375.jpg'
            }
        } else {
            #Write-Warning "Plugin [$Plugin] not found."
            return New-PoshBotCardResponse -Type Warning -Text "Plugin [$Plugin] not found." -ThumbnailUrl 'http://hairmomentum.com/wp-content/uploads/2016/07/warning.png'
        }
    } else {
        #Write-Error -Message "Sorry, builtin plugins can't be disabled. It's for your own good :)"
        return New-PoshBotCardResponse -Type Warning -Text "Sorry, builtin plugins can't be disabled. It's for your own good :)" -Title 'Ya no'
    }
}

function About {
    <#
    .SYNOPSIS
        Display details about PoshBot
    .EXAMPLE
        !about
    #>
    [cmdletbinding()]
    param(
        $Bot
    )

    $path = "$PSScriptRoot/../../PoshBot.psd1"
    $manifest = Import-PowerShellDataFile -Path $path
    $ver = $manifest.ModuleVersion

    $msg = @"
PoshBot v$ver
$($manifest.CopyRight)

https://github.com/devblackops/PoshBot
"@

    New-PoshBotCardResponse -Type Normal -Text $msg
}

Export-ModuleMember -Function *
