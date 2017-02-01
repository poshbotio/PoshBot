
function Help {
    <#
    .SYNOPSIS
        List bot commands
    .EXAMPLE
        !help [<mycommand> | --filter <mycommand>]
    #>
    [PoshBot.BotCommand(Permissions = 'show-help')]
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
                Plugin = $pluginKey
                #Name = $commandKey
                Description = $command.Description
                Usage = $command.Usage
            }
            $availableCommands.Add($x) | Out-Null
        }
    }

    # If we asked for help about a particular plugin or command, filter on it
    if ($PSBoundParameters.ContainsKey('Filter')) {
        $availableCommands = $availableCommands | Where-Object {
            ($_.Command -like "*$Filter*") -or
            ($_.Description -like "*$Filter*") -or
            ($_.Usage -like "*$Filter*")
        }
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
    $hash = [ordered]@{
        Version = '1.0.0'
        Uptime = $uptime
        Plugins = $Bot.PluginManager.Plugins.Count
        Commands = $Bot.PluginManager.Commands.Count
        CommandsExecuted = $Bot.Executor.ExecutedCount
    }

    $status = [pscustomobject]$hash
    #New-PoshBotCardResponse -Type Normal -Text ($status | Format-List | Out-String)
    New-PoshBotCardResponse -Type Normal -Fields $hash -Title 'PoshBot Status'
}

function Get-Command {
    <#
    .SYNOPSIS
        Show details about bot commands
    .EXAMPLE
        !get-command [<commandname> | --command <commandname>]
    #>
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Position = 0)]
        [string]$Command
    )

    if ($PSBoundParameters.ContainsKey('Command')) {
        $title = "Commands matching [$Command]"
        $commandsKeys = @($Bot.PluginManager.Commands.Keys | Where-Object {$_ -like "*$Command*" })
    } else {
        $commandsKeys = @($Bot.PluginManager.Commands.Keys)
    }

    if ($commandsKeys.Count -gt 0) {
        $result = foreach ($key in $commandsKeys) {
            $cmd = $Bot.PluginManager.Commands[$key]
            $o = [pscustomobject][ordered]@{
                Name = $cmd.Name
                Description = $cmd.Description
                Usage = $cmd.Usage -join "`n"
                Enabled = $cmd.Enabled.ToString()
                Permissions = $cmd.AccessFilter.Permissions.Keys | Format-List | Out-string
            }
            $o
        }
        $result = $result | Sort-Object -Property Name

        if ($result.Count -gt 1) {
            $text = ($result | Select-Object -Property Name, Description | Format-Table -AutoSize | Out-String)
        } else {
            $text = ($result | Format-List | Out-String)
        }

        if ($title) {
            New-PoshBotCardResponse -Type Normal -Title $title -Text $text
        } else {
            New-PoshBotCardResponse -Type Normal -Title 'All commands' -Text $text
        }

    } else {
        New-PoshBotCardResponse -Type Error -Text "No commands found matching [$Command] :(" -Title 'Rut row' -ThumbnailUrl 'http://images4.fanpop.com/image/photos/17000000/Scooby-Doo-Where-Are-You-The-Original-Intro-scooby-doo-17020515-500-375.jpg'
    }
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
        !plugin-show [<pluginname> | --plugin <pluginname>]
    #>
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Mandatory, Position = 0)]
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
                Expression = {$_.Value.Usage}
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
                Expression = {$_.Value.Usage}
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
        !plugin-disable [<pluginname> | --plugin <pluginname>]
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
