function Help {
    <#
    .SYNOPSIS
        Show details about bot commands
    .EXAMPLE
        !help [<commandname> | --filter <commandname>]
    #>
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Position = 0)]
        [string]$Filter
    )

    $result = foreach ($pluginKey in $Bot.PluginManager.Plugins.Keys) {
        $plugin = $Bot.PluginManager.Plugins[$pluginKey]

        $pluginVersionKey = $plugin.Keys[0]
        $pluginVersion = $plugin[$pluginVersionKey]

        foreach ($commandKey in $pluginVersion.Commands.Keys) {
            $command = $pluginVersion.Commands[$commandKey]
            $x = [pscustomobject][ordered]@{
                FullCommandName = "$pluginKey`:$CommandKey"
                Command = $CommandKey
                Plugin = $pluginKey
                Description = $command.Description
                Usage = $command.Usage
                Enabled = $command.Enabled.ToString()
                Permissions = $command.AccessFilter.Permissions.Keys | Format-List | Out-string
            }
            $x
        }
    }

    $respParams = @{
        Type = 'Normal'
        DM = $true
    }

    if ($PSBoundParameters.ContainsKey('Filter')) {
        $respParams.Title = "Commands matching [$Filter]"
        $result = @($result | Where-Object {
            ($_.FullCommandName -like "*$Filter*") -or
            ($_.Command -like "*$Filter*") -or
            ($_.Plugin -like "*$Filter*") -or
            ($_.Description -like "*$Filter*") -or
            ($_.Usage -like "*$Filter*")
        })
    } else {
        $respParams.Title = 'All commands'
    }
    $result = $result | Sort-Object -Property FullCommandName

    if ($result) {
        if ($result.Count -ge 1) {
            $respParams.Text = ($result | Select-Object -ExpandProperty FullCommandName | Out-String)
        } else {
            $respParams.Text = ($result | Format-List | Out-String)
        }

        New-PoshBotCardResponse @respParams
    } else {
        New-PoshBotCardResponse -Type Warning -Text "No commands found matching [$Filter] :(" -Title 'Rut row' -ThumbnailUrl 'http://images4.fanpop.com/image/photos/17000000/Scooby-Doo-Where-Are-You-The-Original-Intro-scooby-doo-17020515-500-375.jpg'
    }
}

function Status {
    <#
    .SYNOPSIS
        Get Bot status
    .EXAMPLE
        !status
    #>
    [PoshBot.BotCommand(Permissions = 'view')]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot
    )

    if ($Bot._Stopwatch.IsRunning) {
        $uptime = $Bot._Stopwatch.Elapsed.ToString()
    } else {
        $uptime = $null
    }
    $manifest = Import-PowerShellDataFile -Path "$PSScriptRoot/../../PoshBot.psd1"
    $hash = [ordered]@{
        Version = $manifest.Version
        Uptime = $uptime
        Plugins = $Bot.PluginManager.Plugins.Count
        Commands = $Bot.PluginManager.Commands.Count
        CommandsExecuted = $Bot.Executor.ExecutedCount
    }

    $status = [pscustomobject]$hash
    #New-PoshBotCardResponse -Type Normal -Text ($status | Format-List | Out-String)
    New-PoshBotCardResponse -Type Normal -Fields $hash -Title 'PoshBot Status'
}

function Get-Role {
    <#
    .SYNOPSIS
        Show details about bot roles
    .EXAMPLE
        !get-role [<rolename> | --role <rollname>]
    #>
    [PoshBot.BotCommand(Permissions = 'view-role')]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Position = 0)]
        [string]$Role
    )

    if ($PSBoundParameters.ContainsKey('Role')) {
        $r = $Bot.RoleManager.GetRole($Role)
        if (-not $r) {
            New-PoshBotCardResponse -Type Error -Text "Role [$Role] not found :(" -Title 'Rut row' -ThumbnailUrl 'http://images4.fanpop.com/image/photos/17000000/Scooby-Doo-Where-Are-You-The-Original-Intro-scooby-doo-17020515-500-375.jpg'
            return
        } else {
            $permissions = $r.Permissions.Keys
            $msg = [string]::Empty
            $msg += "`nDescription: $($r.Description)"
            $msg += "`nPermissions:`n$($r.Permissions.Keys | Format-List | Out-String)"
            New-PoshBotCardResponse -Type Normal -Title "Details for role [$Role]" -Text $msg
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

function Plugin-List {
    <#
    .SYNOPSIS
        Get all installed plugins
    .EXAMPLE
        !plugin-list
    #>
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot
    )

    $plugins = foreach ($key in ($Bot.PluginManager.Plugins.Keys | Sort-Object)) {
        $plugin = $Bot.PluginManager.Plugins[$key]

        foreach ($versionKey in $plugin.Keys | Sort -Descending) {
            $pluginVersion = $plugin[$versionKey]
            [pscustomobject][ordered]@{
                Name = $key
                Version = $pluginVersion.Version.ToString()
                Enabled = $pluginVersion.Enabled
            }
        }
    }
    New-PoshBotCardResponse -Type Normal -Text ($plugins | Format-Table -AutoSize | Out-String -Width 150)
}

function Plugin-Show {
    <#
    .SYNOPSIS
        Get the details of a specific plugin
    .EXAMPLE
        !plugin-show (<pluginname> | --plugin <pluginname>) [--version 1.2.3]
    #>
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Mandatory, Position = 0)]
        [string]$Plugin,

        [parameter(Position = 1)]
        [string]$Version
    )

    $p = $Bot.PluginManager.Plugins[$Plugin]
    if ($p) {

        $versions = New-Object -TypeName System.Collections.ArrayList

        if ($PSBoundParameters.ContainsKey('Version')) {
            if ($pv = $p[$Version]) {
                $verions.Add($pv) > $null
            }
        } else {
            foreach ($pvk in $p.Keys | Sort-Object -Descending) {
                $pv = $p[$pvk]
                $versions.Add($pv) > $null
            }
        }

        if ($versions.Count -gt 0) {
            foreach ($pv in $versions) {
                # $r = [pscustomobject]@{
                #     Name = $pv.Name
                #     Version = $pv.Version
                #     Enabled = $pv.Enabled
                #     CommandCount = $pv.Commands.Count
                #     Permissions = $pv.Permissions.Keys
                #     Commands = $pv.Commands
                # }
                $fields = [ordered]@{
                    Title = $pv.Name
                    Version = $pv.Version.ToString()
                    Enabled = $pv.Enabled.ToString()
                    CommandCount = $pv.Commands.Count
                    Permissions = $pv.Permissions.Keys | Format-List | Out-String
                    Commands = $pv.Commands.Keys | Format-List | Out-String
                }

                $msg = [string]::Empty
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
                        Expression = {$_.Value.Usage}
                        Label = 'Usage'
                    }
                )
                $msg += "`nCommands: `n$($pv.Commands.GetEnumerator() | Select-Object -Property $properties | Format-List | Out-String)"
                New-PoshBotCardResponse -Type Normal -Fields $fields
            }
        } else {
            if ($PSBoundParameters.ContainsKey('Version')) {
                New-PoshBotCardResponse -Type Warning -Text "Plugin [$Plugin] version [$Version] not found."
            } else {
                New-PoshBotCardResponse -Type Warning -Text "Plugin [$Plugin] not found."
            }
        }
    } else {
        New-PoshBotCardResponse -Type Warning -Text "Plugin [$Plugin] not found."
    }
}

function Plugin-Install {
    <#
    .SYNOPSIS
        Install a new plugin
    .EXAMPLE
        !plugin-install [<pluginname> | --plugin <pluginname>]
    #>
    [PoshBot.BotCommand(Permissions = 'manage-plugins')]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Mandatory, Position = 0)]
        [string]$Plugin
    )

    if ($Plugin -ne 'Builtin') {
        # Attempt to find the module in $env:PSModulePath or in the configurated repository
        $mod = Get-Module -Name $Plugin -ListAvailable | Select-Object -First 1
        if (-not $mod) {
            $onlineMod = Find-Module -Name $Plugin -Repository $bot.Configuration.PluginRepository -ErrorAction SilentlyContinue
            if ($onlineMod) {
                Install-Module -Name $Plugin -Repository $bot.Configuration.PluginRepository -Scope CurrentUser -Force -ErrorAction Stop
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
        !plugin-enable [<pluginname> | --plugin <pluginname>]
    #>
    [PoshBot.BotCommand(Permissions = 'manage-plugins')]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Mandatory, Position = 0)]
        [string]$Plugin,

        [parameter(Position = 1)]
        [string]$Version
    )

    if ($Plugin -ne 'Builtin') {
        if ($p = $Bot.PluginManager.Plugins[$Plugin]) {
            $pv = $null
            if ($Bot.PluginManager.Plugins[$Plugin].Keys -gt 1) {
                if (-not $PSBoundParameters.ContainsKey('Version')) {
                    $versions = $Bot.PluginManager.Plugins[$Plugin].Keys -join ', ' | Out-String
                    return New-PoshBotCardResponse -Type Warning -Text "Plugin [$Plugin] has multiple versions installed. Specify version from list`n$versions" -ThumbnailUrl 'http://hairmomentum.com/wp-content/uploads/2016/07/warning.png'
                } else {
                    $pv = $Bot.PluginManager.Plugins[$Plugin][$Version]
                }
            } else {
                $pv = $p
            }

            if ($pv) {
                try {
                    $Bot.PluginManager.ActivatePlugin($pv)
                    #Write-Output "Plugin [$Plugin] activated. All commands in this plugin are now enabled."
                    return New-PoshBotCardResponse -Type Normal -Text "Plugin [$Plugin] activated. All commands in this plugin are now enabled." -ThumbnailUrl 'https://www.streamsports.com/images/icon_green_check_256.png'
                } catch {
                    #Write-Error $_
                    return New-PoshBotCardResponse -Type Error -Text $_.Exception.Message -Title 'Rut row' -ThumbnailUrl 'http://images4.fanpop.com/image/photos/17000000/Scooby-Doo-Where-Are-You-The-Original-Intro-scooby-doo-17020515-500-375.jpg'
                }
            } else {
                return New-PoshBotCardResponse -Type Warning -Text "Plugin [$Plugin] version [$Version] not found." -ThumbnailUrl 'http://hairmomentum.com/wp-content/uploads/2016/07/warning.png'
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
        !plugin-disable [<pluginname> | --plugin <pluginname>]
    #>
    [PoshBot.BotCommand(Permissions = 'manage-plugins')]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Mandatory, Position = 0)]
        [string]$Plugin,

        [parameter(Position = 1)]
        [string]$Version
    )

    if ($Plugin -ne 'Builtin') {
        if ($p = $bot.PluginManager.Plugins[$Plugin]) {
            $pv = $null
            if ($Bot.PluginManager.Plugins[$Plugin].Keys -gt 1) {
                if (-not $PSBoundParameters.ContainsKey('Version')) {
                    $versions = $Bot.PluginManager.Plugins[$Plugin].Keys -join ', ' | Out-String
                    return New-PoshBotCardResponse -Type Warning -Text "Plugin [$Plugin] has multiple versions installed. Specify version from list`n$versions" -ThumbnailUrl 'http://hairmomentum.com/wp-content/uploads/2016/07/warning.png'
                } else {
                    $pv = $Bot.PluginManager.Plugins[$Plugin][$Version]
                }
            } else {
                $pv = $p
            }

            if ($pv) {
                try {
                    $bot.PluginManager.DeactivatePlugin($pv)
                    #Write-Output "Plugin [$Plugin] deactivated. All commands in this plugin are now disabled."
                    return New-PoshBotCardResponse -Type Normal -Text "Plugin [$Plugin] deactivated. All commands in this plugin are now disabled." -Title 'Plugin deactivated' -ThumbnailUrl 'https://www.streamsports.com/images/icon_green_check_256.png'
                } catch {
                    #Write-Error $_
                    return New-PoshBotCardResponse -Type Error -Text $_.Exception.Message -Title 'Rut row' -ThumbnailUrl 'http://images4.fanpop.com/image/photos/17000000/Scooby-Doo-Where-Are-You-The-Original-Intro-scooby-doo-17020515-500-375.jpg'
                }
            } else {
                return New-PoshBotCardResponse -Type Warning -Text "Plugin [$Plugin] version [$Version] not found." -ThumbnailUrl 'http://hairmomentum.com/wp-content/uploads/2016/07/warning.png'
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

function Get-Group {
    <#
    .SYNOPSIS
        Show details about bot groups
    .EXAMPLE
        !get-group [<groupname> | --name <groupname>]
    #>
    [PoshBot.BotCommand(Permissions = 'view-group')]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Position = 0)]
        [string]$Name
    )

    if ($PSBoundParameters.ContainsKey('Name')) {
        $g = $Bot.RoleManager.GetGroup($Name)
        if (-not $g) {
            New-PoshBotCardResponse -Type Error -Text "Group [$Name] not found :(" -Title 'Rut row' -ThumbnailUrl 'http://images4.fanpop.com/image/photos/17000000/Scooby-Doo-Where-Are-You-The-Original-Intro-scooby-doo-17020515-500-375.jpg'
            return
        } else {
            $membership = [pscustomobject]@{
                Users = $g.Users.Keys | foreach-object {
                    $Bot.RoleManager.ResolveUserToId($_)
                }
                Roles = $g.Roles.Keys
            }
            $msg = [string]::Empty
            $msg += "`nDescription: $($g.Description)"
            $msg += "`nMembers:`n$($membership | Format-Table | Out-String)"
            New-PoshBotCardResponse -Type Normal -Title "Details for group [$Name]" -Text $msg
        }
    } else {
        $groups = foreach ($key in ($Bot.RoleManager.Groups.Keys | Sort-Object)) {
            [pscustomobject][ordered]@{
                Name = $key
                Description = $Bot.RoleManager.Groups[$key].Description
                Users = $Bot.RoleManager.Groups[$key].Users.Keys
                Roles = $Bot.RoleManager.Groups[$key].Roles.Keys
            }
        }
        New-PoshBotCardResponse -Type Normal -Text ($groups | Format-List | Out-String)
    }
}

function Get-Permission {
    <#
    .SYNOPSIS
        Show details about bot permissions
    .EXAMPLE
        !get-permission [<permissionname> | --name <permissionname>]
    #>
    [PoshBot.BotCommand(Permissions = 'view')]
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
            New-PoshBotCardResponse -Type Error -Text "Permission [$Name] not found :(" -Title 'Rut row' -ThumbnailUrl 'http://images4.fanpop.com/image/photos/17000000/Scooby-Doo-Where-Are-You-The-Original-Intro-scooby-doo-17020515-500-375.jpg'
            return
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

function New-Group {
    <#
    .SYNOPSIS
        Create a new group
    .EXAMPLE
        !new-group (<groupname> | --name <groupname>) (<groupdescription> | --description <groupdescription>)
    #>
    [PoshBot.BotCommand(Permissions = 'manage-groups')]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Mandatory, Position = 0)]
        [string]$Name,

        [parameter(Position = 1)]
        [string]$Description
    )

    $group = [Group]::New($Name)
    if ($PSBoundParameters.ContainsKey('Description')) {
        $group.Description = $Description
    }

    $Bot.RoleManager.AddGroup($group)
    if ($g = $Bot.RoleManager.GetGroup($Name)) {
        return New-PoshBotCardResponse -Type Normal -Text "Group [$Name] created." -ThumbnailUrl 'https://www.streamsports.com/images/icon_green_check_256.png'
    } else {
        return New-PoshBotCardResponse -Type Warning -Text "Group [$Name] could not be created. Check logs for more information." -ThumbnailUrl 'http://hairmomentum.com/wp-content/uploads/2016/07/warning.png'
    }
}

function New-Role {
    <#
    .SYNOPSIS
        Create a new role
    .EXAMPLE
        !new-role (<rolename> | --name <rolename>) (<roledescription>) | --description <roledescription>)
    #>
    [PoshBot.BotCommand(Permissions = 'manage-roles')]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Mandatory, Position = 0)]
        [string]$Name,

        [parameter(Position = 1)]
        [string]$Description
    )

    $role = [Role]::New($Name)
    if ($PSBoundParameters.ContainsKey('Description')) {
        $role.Description = $Description
    }

    $Bot.RoleManager.AddRole($role)
    if ($g = $Bot.RoleManager.GetRole($Name)) {
        return New-PoshBotCardResponse -Type Normal -Text "Role [$Name] created." -ThumbnailUrl 'https://www.streamsports.com/images/icon_green_check_256.png'
    } else {
        return New-PoshBotCardResponse -Type Warning -Text "Role [$Name] could not be created. Check logs for more information." -ThumbnailUrl 'http://hairmomentum.com/wp-content/uploads/2016/07/warning.png'
    }
}

function Add-RolePermission {
    <#
    .SYNOPSIS
        Add a permission to a role
    .EXAMPLE
        !add-rolepermission (<rolename> | --role <rolename>) (<permissionname> | --permission <permissionname>)
    #>
    [PoshBot.BotCommand(Permissions = 'manage-roles')]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Mandatory, Position = 0)]
        [string]$Role,

        [parameter(Position = 1)]
        [string]$Permission
    )

    if ($r = $Bot.RoleManager.GetRole($Role)) {
        if ($p = $Bot.RoleManager.Permissions[$Permission]) {
            try {
                $Bot.RoleManager.AddPermissionToRole($Permission, $Role)
                return New-PoshBotCardResponse -Type Normal -Text "Permission [$Permission] added to role [$Role]." -ThumbnailUrl 'https://www.streamsports.com/images/icon_green_check_256.png'
            } catch {
                return New-PoshBotCardResponse -Type Error -Text "Failed to add [$Permission] to group [$Role]" -ThumbnailUrl 'https://cdn0.iconfinder.com/data/icons/shift-free/32/Error-128.png'
            }
        } else {
            New-PoshBotCardResponse -Type Warning -Text "Permission [$Permission] not found :(" -Title 'Rut row' -ThumbnailUrl 'http://images4.fanpop.com/image/photos/17000000/Scooby-Doo-Where-Are-You-The-Original-Intro-scooby-doo-17020515-500-375.jpg'
        }
    } else {
        New-PoshBotCardResponse -Type Warning -Text "Role [$Role] not found :(" -Title 'Rut row' -ThumbnailUrl 'http://images4.fanpop.com/image/photos/17000000/Scooby-Doo-Where-Are-You-The-Original-Intro-scooby-doo-17020515-500-375.jpg'
    }
}

function Remove-RolePermission {
    <#
    .SYNOPSIS
        Remove a permission from a role
    .EXAMPLE
        !remove-rolepermission (<rolename> | --role <rolename>) (<permissioname> | --permission <permissioname>)
    #>
    [PoshBot.BotCommand(Permissions = 'manage-roles')]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Mandatory, Position = 0)]
        [string]$Role,

        [parameter(Position = 1)]
        [string]$Permission
    )

    if ($r = $Bot.RoleManager.GetRole($Role)) {
        if ($p = $Bot.RoleManager.Permissions[$Permission]) {
            try {
                $Bot.RoleManager.RemovePermissionFromRole($Permission, $Role)
                return New-PoshBotCardResponse -Type Normal -Text "Permission [$Permission] removed from role [$role]." -ThumbnailUrl 'https://www.streamsports.com/images/icon_green_check_256.png'
            } catch {
                return New-PoshBotCardResponse -Type Error -Text "Failed to remove [$Permission] from role [$role]" -ThumbnailUrl 'https://cdn0.iconfinder.com/data/icons/shift-free/32/Error-128.png'
            }
        } else {
            New-PoshBotCardResponse -Type Warning -Text "Permission [$Permission] not found :(" -Title 'Rut row' -ThumbnailUrl 'http://images4.fanpop.com/image/photos/17000000/Scooby-Doo-Where-Are-You-The-Original-Intro-scooby-doo-17020515-500-375.jpg'
        }
    } else {
        New-PoshBotCardResponse -Type Warning -Text "Role [$Role] not found :(" -Title 'Rut row' -ThumbnailUrl 'http://images4.fanpop.com/image/photos/17000000/Scooby-Doo-Where-Are-You-The-Original-Intro-scooby-doo-17020515-500-375.jpg'
    }
}

function Add-GroupUser {
    <#
    .SYNOPSIS
        Add a user to a group
    .EXAMPLE
        !add-groupuser (<groupname> | --group <groupname>) (<username> | --user <username>)
    #>
    [PoshBot.BotCommand(Permissions = 'manage-groups')]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Mandatory, Position = 0)]
        [string]$Group,

        [parameter(Position = 1)]
        [string]$User
    )

    if ($g = $Bot.RoleManager.GetGroup($Group)) {
        # Resolve username to user id
        if ($userId = $Bot.RoleManager.ResolveUserToId($User)) {
            try {
                $bot.RoleManager.AddUserToGroup($userId, $Group)
                return New-PoshBotCardResponse -Type Normal -Text "User [$User] added to group [$Group]." -ThumbnailUrl 'https://www.streamsports.com/images/icon_green_check_256.png'
            } catch {
                return New-PoshBotCardResponse -Type Error -Text "Failed to add [$User] to group [$Group]" -ThumbnailUrl 'https://cdn0.iconfinder.com/data/icons/shift-free/32/Error-128.png'
            }
        } else {
            New-PoshBotCardResponse -Type Warning -Text "User [$User] not found :(" -Title 'Rut row' -ThumbnailUrl 'http://images4.fanpop.com/image/photos/17000000/Scooby-Doo-Where-Are-You-The-Original-Intro-scooby-doo-17020515-500-375.jpg'
        }
    } else {
        New-PoshBotCardResponse -Type Warning -Text "Group [$Group] not found :(" -Title 'Rut row' -ThumbnailUrl 'http://images4.fanpop.com/image/photos/17000000/Scooby-Doo-Where-Are-You-The-Original-Intro-scooby-doo-17020515-500-375.jpg'
    }
}

function Remove-GroupUser {
    <#
    .SYNOPSIS
        Remove a user to a group
    .EXAMPLE
        !remove-groupuser (<groupname> | --group <groupname>) (<username> | --user <username>)
    #>
    [PoshBot.BotCommand(Permissions = 'manage-groups')]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Mandatory, Position = 0)]
        [string]$Group,

        [parameter(Position = 1)]
        [string]$User
    )

    if ($g = $Bot.RoleManager.GetGroup($Group)) {
        if ($userId = $Bot.RoleManager.ResolveUserToId($User)) {
            try {
                $bot.RoleManager.RemoveUserFromGroup($userId, $Group)
                return New-PoshBotCardResponse -Type Normal -Text "User [$User] removed from group [$Group]." -ThumbnailUrl 'https://www.streamsports.com/images/icon_green_check_256.png'
            } catch {
                return New-PoshBotCardResponse -Type Error -Text "Failed to remove [$User] from group [$Group]" -ThumbnailUrl 'https://cdn0.iconfinder.com/data/icons/shift-free/32/Error-128.png'
            }
        } else {
            New-PoshBotCardResponse -Type Warning -Text "User [$User] not found :(" -Title 'Rut row' -ThumbnailUrl 'http://images4.fanpop.com/image/photos/17000000/Scooby-Doo-Where-Are-You-The-Original-Intro-scooby-doo-17020515-500-375.jpg'
        }
    } else {
        New-PoshBotCardResponse -Type Warning -Text "Group [$Group] not found :(" -Title 'Rut row' -ThumbnailUrl 'http://images4.fanpop.com/image/photos/17000000/Scooby-Doo-Where-Are-You-The-Original-Intro-scooby-doo-17020515-500-375.jpg'
    }
}

function Add-GroupRole {
    <#
    .SYNOPSIS
        Add a role to a group
    .EXAMPLE
        !add-grouprole (<groupname> | --group <groupname>) (<rolename> | --role <rolename>)
    #>
    [PoshBot.BotCommand(Permissions = 'manage-groups')]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Mandatory, Position = 0)]
        [string]$Group,

        [parameter(Position = 1)]
        [string]$Role
    )

    if ($g = $Bot.RoleManager.GetGroup($Group)) {
        if ($r = $Bot.RoleManager.GetRole($Role)) {
            try {
                $bot.RoleManager.AddRoleToGroup($Role, $Group)
                return New-PoshBotCardResponse -Type Normal -Text "Role [$Role] added to group [$Group]." -ThumbnailUrl 'https://www.streamsports.com/images/icon_green_check_256.png'
            } catch {
                return New-PoshBotCardResponse -Type Error -Text "Failed to add [$Role] to group [$Group]" -ThumbnailUrl 'https://cdn0.iconfinder.com/data/icons/shift-free/32/Error-128.png'
            }
        } else {
            New-PoshBotCardResponse -Type Warning -Text "Role [$Role] not found :(" -Title 'Rut row' -ThumbnailUrl 'http://images4.fanpop.com/image/photos/17000000/Scooby-Doo-Where-Are-You-The-Original-Intro-scooby-doo-17020515-500-375.jpg'
        }
    } else {
        New-PoshBotCardResponse -Type Warning -Text "Group [$Group] not found :(" -Title 'Rut row' -ThumbnailUrl 'http://images4.fanpop.com/image/photos/17000000/Scooby-Doo-Where-Are-You-The-Original-Intro-scooby-doo-17020515-500-375.jpg'
    }
}

function Remove-GroupRole {
    <#
    .SYNOPSIS
        Remove a role from a group
    .EXAMPLE
        !remove-grouprole (<groupname> | --group <groupname>) (<rolename> | --role <rolename>)
    #>
    [PoshBot.BotCommand(Permissions = 'manage-groups')]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Mandatory, Position = 0)]
        [string]$Group,

        [parameter(Position = 1)]
        [string]$Role
    )

    if ($g = $Bot.RoleManager.GetGroup($Group)) {
        if ($r = $Bot.RoleManager.GetRole($Role)) {
            try {
                $bot.RoleManager.RemoveRoleFromGroup($Role, $Group)
                return New-PoshBotCardResponse -Type Normal -Text "Role [$Role] removed from group [$Group]." -ThumbnailUrl 'https://www.streamsports.com/images/icon_green_check_256.png'
            } catch {
                return New-PoshBotCardResponse -Type Error -Text "Failed to remove [$Role] from group [$Group]" -ThumbnailUrl 'https://cdn0.iconfinder.com/data/icons/shift-free/32/Error-128.png'
            }
        } else {
            New-PoshBotCardResponse -Type Warning -Text "Role [$Role] not found :(" -Title 'Rut row' -ThumbnailUrl 'http://images4.fanpop.com/image/photos/17000000/Scooby-Doo-Where-Are-You-The-Original-Intro-scooby-doo-17020515-500-375.jpg'
        }
    } else {
        New-PoshBotCardResponse -Type Warning -Text "Group [$Group] not found :(" -Title 'Rut row' -ThumbnailUrl 'http://images4.fanpop.com/image/photos/17000000/Scooby-Doo-Where-Are-You-The-Original-Intro-scooby-doo-17020515-500-375.jpg'
    }
}

function About {
    <#
    .SYNOPSIS
        Display details about PoshBot
    .EXAMPLE
        !about
    #>
    [PoshBot.BotCommand(Permissions = 'view')]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
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
