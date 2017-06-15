
# Thumbnails for card responses
$thumb = @{
    rutrow = 'http://images4.fanpop.com/image/photos/17000000/Scooby-Doo-Where-Are-You-The-Original-Intro-scooby-doo-17020515-500-375.jpg'
    don = 'http://p1cdn05.thewrap.com/images/2015/06/don-draper-shrug.jpg'
    warning = 'http://hairmomentum.com/wp-content/uploads/2016/07/warning.png'
    error = 'https://cdn0.iconfinder.com/data/icons/shift-free/32/Error-128.png'
    success = 'https://www.streamsports.com/images/icon_green_check_256.png'
}

function Get-CommandHelp {
    <#
    .SYNOPSIS
        Show details and help information about bot commands.
    .PARAMETER Filter
        The text to filter available commands and plugins on.
    .PARAMETER Detailed
        Show more detailed help information for the command.
    .PARAMETER Type
        Only return commands of specified type.
    .EXAMPLE
        !help --filter new-group

        Get help on the 'New-Group' command.
    .EXAMPLE
        !help new-group --detailed

        Get detailed help on the 'New-group' command
    .EXAMPLE
        !help --type regex

        List all commands with the [regex] trigger type.
    #>
    [PoshBot.BotCommand(
        Aliases = ('man', 'help')
    )]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Position = 0)]
        [string]$Filter,

        [switch]$Detailed,

        [ValidateSet('*', 'Command', 'Event', 'Regex')]
        [string]$Type = '*'
    )

    $allCommands = $Bot.PluginManager.Commands.GetEnumerator() |
        Where-Object {$_.Value.TriggerType -like $Type} |
        Foreach-Object {
            $arrPlgCmdVer = $_.Name.Split(':')
            $plugin = $arrPlgCmdVer[0]
            $command = $arrPlgCmdVer[1]
            $version = $arrPlgCmdVer[2]
            [pscustomobject]@{
                FullCommandName = "$plugin`:$command"
                Command = $command
                Type = $_.Value.TriggerType.ToString()
                Aliases = ($_.Value.Aliases -join ', ')
                Plugin = $plugin
                Version = $version
                Description = $_.Value.Description
                Usage = ($_.Value.Usage | Format-List | Out-string).Trim()
                Enabled = $_.Value.Enabled.ToString()
                Permissions = ($_.Value.AccessFilter.Permissions.Keys | Format-List | Out-string).Trim()
            }
    }

    $respParams = @{
        Type = 'Normal'
    }

    $result = @()
    if ($PSBoundParameters.ContainsKey('Filter')) {
        $respParams.Title = "Commands matching [$Filter]"
        $result = @($allCommands | Where-Object {
            ($_.FullCommandName -like "*$Filter*") -or
            ($_.Command -like "*$Filter*") -or
            ($_.Plugin -like "*$Filter*") -or
            ($_.Version -like "*$Filter*") -or
            ($_.Description -like "*$Filter*") -or
            ($_.Usage -like "*$Filter*") -or
            ($_.Aliases -like "*$Filter*")
        })
    } else {
        $respParams.Title = 'All commands'
        $result = $allCommands
    }
    $result = $result | Sort-Object -Property FullCommandName

    if ($result) {
        if ($result.Count -ge 1) {
            $fields = @(
                'FullCommandName'
                @{l='Aliases';e={$_.Aliases -join ', '}}
                @{l='Type';e={$_.Type}}
                'Version'
            )
            $respParams.Text = ($result | Select-Object -Property $fields | Out-String)
        } else {
            if ($Detailed) {
                $fullVersionName = "$($result.FullCommandName)`:$($result.Version)"
                $manString = ($Bot.PluginManager.Commands[$fullVersionName] | Get-Help -Detailed | Out-String)
                $result | Add-Member -MemberType NoteProperty -Name Manual -Value "`n$manString"
            }
            $respParams.Text = ($result | Format-List | Out-String -Width 150).Trim()
        }

        New-PoshBotTextResponse -Text $respParams.Text -AsCode
    } else {
        New-PoshBotCardResponse -Type Warning -Text "No commands found matching [$Filter] :(" -Title 'Rut row' -ThumbnailUrl $thumb.rutrow
    }
}

function Status {
    <#
    .SYNOPSIS
        Get bot status information such as the version, uptime, and number of plugin/commands installed.
    .EXAMPLE
        !status

        Show the current status of the bot instance.
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
        Version = $manifest.ModuleVersion
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

function Get-Plugin {
    <#
    .SYNOPSIS
        Get the details of a specific plugin or list all plugins.
    .PARAMETER Name
        The name of the plugin to get.
    .PARAMETER Version
        The version of the plugin to get.
    .EXAMPLE
        !get-plugin builtin

        Get the details of the [builtin] plugin.
    .EXAMPLE
        !get-plugin --name builtin --version 0.5.0

        Get the details of version [0.5.0] of the [builtin] plugin.
    #>
    [PoshBot.BotCommand(
        Aliases = ('gp', 'getplugin')
    )]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Position = 0)]
        [string]$Name,

        [parameter(Position = 1)]
        [string]$Version
    )

    if ($PSBoundParameters.ContainsKey('Name')) {

        $p = $Bot.PluginManager.Plugins[$Name]
        if ($p) {

            $versions = New-Object -TypeName System.Collections.ArrayList

            if ($PSBoundParameters.ContainsKey('Version')) {
                if ($pv = $p[$Version]) {
                    $versions.Add($pv) > $null
                }
            } else {
                foreach ($pvk in $p.Keys | Sort-Object -Descending) {
                    $pv = $p[$pvk]
                    $versions.Add($pv) > $null
                }
            }

            if ($versions.Count -gt 0) {
                if ($PSBoundParameters.ContainsKey('Version')) {
                    $versions = $versions | Where Version -eq $Version
                }
                foreach ($pv in $versions) {
                    $fields = [ordered]@{
                        Name = $pv.Name
                        Version = $pv.Version.ToString()
                        Enabled = $pv.Enabled.ToString()
                        CommandCount = $pv.Commands.Count
                        Permissions = $pv.Permissions.Keys | Format-List | Out-String
                        Commands = $pv.Commands.Keys | Sort-Object | Format-List | Out-String
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
                    New-PoshBotCardResponse -Type Warning -Text "Plugin [$Name] version [$Version] not found."
                } else {
                    New-PoshBotCardResponse -Type Warning -Text "Plugin [$Name] not found."
                }
            }
        } else {
            New-PoshBotCardResponse -Type Warning -Text "Plugin [$Name] not found."
        }
    } else {
        $plugins = foreach ($key in ($Bot.PluginManager.Plugins.Keys | Sort-Object)) {
            $p = $Bot.PluginManager.Plugins[$key]
            foreach ($versionKey in $p.Keys | Sort-Object -Descending) {
                $pluginVersion = $p[$versionKey]
                [pscustomobject][ordered]@{
                    Name = $key
                    Version = $pluginVersion.Version.ToString()
                    Enabled = $pluginVersion.Enabled
                }
            }
        }
        New-PoshBotCardResponse -Type Normal -Text ($plugins | Format-Table -AutoSize | Out-String -Width 80)
    }
}

function Install-Plugin {
    <#
    .SYNOPSIS
        Install a new plugin.
    .PARAMETER Name
        The name of the PoshBot plugin (PowerShell module) to install.
        The plugin must already exist in $env:PSModulePath or be present
        in on of the configured plugin repositories (PowerShell repositories).
        If not already installed, PoshBot will install the module from the repository.
    .PARAMETER Version
        The specific version of the plugin to install.
    .EXAMPLE
        !install-plugin nameit

        Install the [NameIt] plugin.
    .EXAMPLE
        !install-plugin --name PoshBot.XKCD --version 1.0.0

        Install version [1.0.0] of the [PoshBot.XKCD] plugin.
    #>
    [PoshBot.BotCommand(
        Aliases = ('ip', 'installplugin'),
        Permissions = 'manage-plugins'
    )]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Mandatory, Position = 0)]
        [string]$Name,

        [parameter(Position = 1)]
        [ValidateScript({
            if ($_ -as [Version]) {
                $true
            } else {
                throw 'Version parameter must be a valid semantic version string (1.2.3)'
            }
        })]
        [string]$Version
    )

    if ($Name -ne 'Builtin') {

        # Attempt to find the module in $env:PSModulePath or in the configurated repository
        if ($PSBoundParameters.ContainsKey('Version')) {
            $mod = Get-Module -Name $Name -ListAvailable | Where-Object {$_.Version -eq $Version}
        } else {
            $mod = @(Get-Module -Name $Name -ListAvailable | Sort-Object -Property Version -Descending)[0]
        }
        if (-not $mod) {

            # Attemp to find the module in our PS repository
            $findParams = @{
                Name = $Name
                Repository = $bot.Configuration.PluginRepository
                ErrorAction = 'SilentlyContinue'
            }
            if ($PSBoundParameters.ContainsKey('Version')) {
                $findParams.RequiredVersion = $Version
            }

            if ($onlineMod = Find-Module @findParams) {
                $onlineMod | Install-Module -Scope CurrentUser -Force -AllowClobber

                if ($PSBoundParameters.ContainsKey('Version')) {
                    $mod = Get-Module -Name $Name -ListAvailable | Where-Object {$_.Version -eq $Version}
                } else {
                    $mod = @(Get-Module -Name $Name -ListAvailable | Sort-Object -Property Version -Descending)[0]
                }
            }
        }

        if ($mod) {
            try {
                $existingPlugin = $Bot.PluginManager.Plugins[$Name]
                $existingPluginVersions = $existingPlugin.Keys
                if ($existingPluginVersions -notcontains $mod.Version) {
                    $Bot.PluginManager.InstallPlugin($mod.Path, $true)
                    $resp = Get-Plugin -Bot $bot -Name $Name -Version $mod.Version
                    if (-not ($resp | Get-Member -Name 'Title' -MemberType NoteProperty)) {
                        $resp | Add-Member -Name 'Title' -MemberType NoteProperty -Value $null
                    }
                    $resp.Title = "Plugin [$Name] version [$($mod.Version)] successfully installed"
                } else {
                    $resp = New-PoshBotCardResponse -Type Warning -Text "Plugin [$Name] version [$($mod.Version)] is already installed" -Title 'Plugin already installed'
                }
            } catch {
                $resp = New-PoshBotCardResponse -Type Error -Text $_.Exception.Message -Title 'Rut row' -ThumbnailUrl $thumb.rutrow
            }
        } else {
            if ($PSBoundParameters.ContainsKey('Version')) {
                $text = "Plugin [$Name] version [$Version] not found in configured plugin directory [$($Bot.Configuration.PluginDirectory)], PSModulePath, or repository [$($Bot.Configuration.PluginRepository)]"
            } else {
                $text = "Plugin [$Name] not found in configured plugin directory [$($Bot.Configuration.PluginDirectory)], PSModulePath, or repository [$($Bot.Configuration.PluginRepository)]"
            }
            $resp = New-PoshBotCardResponse -Type Warning -Text $text -ThumbnailUrl 'http://p1cdn05.thewrap.com/images/2015/06/don-draper-shrug.jpg'
        }
    } else {
        $resp = New-PoshBotCardResponse -Type Warning -Text 'The builtin plugin is already... well... builtin :)' -Title 'Not gonna do it'
    }

    $resp
}

function Enable-Plugin {
    <#
    .SYNOPSIS
        Enable a currently loaded plugin.
    .PARAMETER Name
        The name of the plugin to enable.
    .PARAMETER Version
        The specific version of the plugin to enable.
    .EXAMPLE
        !enable-plugin nameit

        Enable the [NameIt] plugin.
    .EXAMPLE
        !enable-plugin --name PoshBot.XKCD --version 1.0.0

        Enable version [1.0.0] of the [PoshBot.XKCD] module.
    #>
    [PoshBot.BotCommand(
        Aliases = 'enableplugin',
        Permissions = 'manage-plugins'
    )]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Mandatory, Position = 0)]
        [string]$Name,

        [parameter(Position = 1)]
        [string]$Version
    )

    if ($Name -ne 'Builtin') {
        if ($p = $Bot.PluginManager.Plugins[$Name]) {
            $pv = $null
            if ($p.Keys.Count -gt 1) {
                if (-not $PSBoundParameters.ContainsKey('Version')) {
                    $versions = $p.Keys -join ', ' | Out-String
                    return New-PoshBotCardResponse -Type Warning -Text "Plugin [$Name] has multiple versions installed. Specify version from list`n$versions" -ThumbnailUrl $thumb.warning
                } else {
                    $pv = $p[$Version]
                }
            } else {
                $pvKey = $p.Keys[0]
                $pv = $p[$pvKey]
            }

            if ($pv) {
                try {
                    $Bot.PluginManager.ActivatePlugin($pv.Name, $pv.Version)
                    #$Bot.PluginManager.ActivatePlugin($pv)
                    #Write-Output "Plugin [$Plugin] activated. All commands in this plugin are now enabled."
                    return New-PoshBotCardResponse -Type Normal -Text "Plugin [$Name] activated. All commands in this plugin are now enabled." -ThumbnailUrl $thumb.success
                } catch {
                    #Write-Error $_
                    return New-PoshBotCardResponse -Type Error -Text $_.Exception.Message -Title 'Rut row' -ThumbnailUrl $thumb.rutrow
                }
            } else {
                return New-PoshBotCardResponse -Type Warning -Text "Plugin [$Name] version [$Version] not found." -ThumbnailUrl $thumb.warning
            }
        } else {
            #Write-Warning "Plugin [$Plugin] not found."
            return New-PoshBotCardResponse -Type Warning -Text "Plugin [$Name] not found." -ThumbnailUrl $thumb.warning
        }
    } else {
        #Write-Output "Builtin plugins can't be disabled so no need to enable them."
        return New-PoshBotCardResponse -Type Normal -Text "Builtin plugins can't be disabled so no need to enable them." -Title 'Ya no'
    }
}

function Disable-Plugin {
    <#
    .SYNOPSIS
        Disable a currently loaded plugin.
    .PARAMETER Name
        The name of the plugin to disable.
    .PARAMETER Version
        The specific version of the plugin to disable.
    .EXAMPLE
        !disable-plugin nameit

        Disable the [NameIt] plugin.
    .EXAMPLE
        !disable-plugin --name PoshBot.XKCD --version 1.0.0

        Disable version [1.0.0] of the [PoshBot.XKCD] module.
    #>
    [PoshBot.BotCommand(
        Aliases = ('dp', 'disableplugin'),
        Permissions = 'manage-plugins'
    )]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Mandatory, Position = 0)]
        [string]$Name,

        [parameter(Position = 1)]
        [string]$Version
    )

    if ($Name -ne 'Builtin') {
        if ($p = $Bot.PluginManager.Plugins[$Name]) {
            $pv = $null
            if ($p.Keys.Count -gt 1) {
                if (-not $PSBoundParameters.ContainsKey('Version')) {
                    $versions = $p.Keys -join ', ' | Out-String
                    return New-PoshBotCardResponse -Type Warning -Text "Plugin [$Name] has multiple versions installed. Specify version from list`n$versions" -ThumbnailUrl $thumb.warning
                } else {
                    $pv = $p[$Version]
                }
            } else {
                $pvKey = $p.Keys[0]
                $pv = $p[$pvKey]
            }

            if ($pv) {
                try {
                    $Bot.PluginManager.DeactivatePlugin($pv.Name, $pv.Version)
                    return New-PoshBotCardResponse -Type Normal -Text "Plugin [$Name] deactivated. All commands in this plugin are now disabled." -Title 'Plugin deactivated' -ThumbnailUrl $thumb.success
                } catch {
                    return New-PoshBotCardResponse -Type Error -Text $_.Exception.Message -Title 'Rut row' -ThumbnailUrl $thumb.rutrow
                }
            } else {
                return New-PoshBotCardResponse -Type Warning -Text "Plugin [$Name] version [$Version] not found." -ThumbnailUrl $thumb.warning
            }
        } else {
            return New-PoshBotCardResponse -Type Warning -Text "Plugin [$Name] not found." -ThumbnailUrl $thumb.warning
        }
    } else {
        return New-PoshBotCardResponse -Type Warning -Text "Sorry, builtin plugins can't be disabled. It's for your own good :)" -Title 'Ya no'
    }
}

function Remove-Plugin {
    <#
    .SYNOPSIS
        Removes a currently loaded plugin.
    .PARAMETER Name
        The name of the plugin to remove.
    .PARAMETER Version
        The specific version of the plugin to remove.
    .EXAMPLE
        !remove-plugin nameit

        Remove the [NameIt] plugin.
    .EXAMPLE
        !remove-plugin --name PoshBot.XKCD --version 1.0.0

        Remove version [1.0.0] of the [PoshBot.XKCD] module.
    #>
    [PoshBot.BotCommand(
        Aliases = ('rp', 'removeplugin'),
        Permissions = 'manage-plugins'
    )]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Mandatory, Position = 0)]
        [string]$Name,

        [parameter(Position = 1)]
        [string]$Version
    )

    if ($Name -ne 'Builtin') {
        if ($p = $Bot.PluginManager.Plugins[$Name]) {
            $pv = $null
            if ($p.Keys.Count -gt 1) {
                if (-not $PSBoundParameters.ContainsKey('Version')) {
                    $versions = $p.Keys -join ', ' | Out-String
                    New-PoshBotCardResponse -Type Warning -Text "Plugin [$Name] has multiple versions installed. Specify version from list`n$versions" -ThumbnailUrl $thumb.warning
                    return
                } else {
                    $pv = $p[$Version]
                }
            } else {
                $pvKey = $p.Keys[0]
                $pv = $p[$pvKey]
            }

            if ($pv) {
                try {
                    $Bot.PluginManager.RemovePlugin($pv.Name, $pv.Version)
                    New-PoshBotCardResponse -Type Normal -Text "Plugin [$Name] version [$($pv.Version)] and all related commands have been removed." -Title 'Plugin Removed' -ThumbnailUrl $thumb.success
                } catch {
                    New-PoshBotCardResponse -Type Error -Text $_.Exception.Message -Title 'Rut row' -ThumbnailUrl $thumb.rutrow
                }
            } else {
                New-PoshBotCardResponse -Type Warning -Text "Plugin [$Name] version [$Version] not found." -ThumbnailUrl $thumb.warning
            }
        } else {
            New-PoshBotCardResponse -Type Warning -Text "Plugin [$Name] not found." -ThumbnailUrl $thumb.warning
        }
    } else {
        New-PoshBotCardResponse -Type Warning -Text "Sorry, builtin plugins can't be removed. It's for your own good :)" -Title 'Ya no'
    }
}

function Get-Group {
    <#
    .SYNOPSIS
        Show details about bot groups.
    .PARAMETER Name
        The name of the group to get.
    .EXAMPLE
        !get-group

        Get a list of all groups.
    .EXAMPLE
        !get-group --name admin

        Get details about the [Admin] group.
    #>
    [PoshBot.BotCommand(
        Aliases = ('gg', 'getgroup'),
        Permissions = 'view-group'
    )]
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
            New-PoshBotCardResponse -Type Error -Text "Group [$Name] not found :(" -Title 'Rut row' -ThumbnailUrl $thumb.rutrow
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
                Users = $Bot.RoleManager.Groups[$key].Users.Keys | foreach-object {
                    $Bot.RoleManager.ResolveUserToId($_)
                }
                Roles = $Bot.RoleManager.Groups[$key].Roles.Keys
            }
        }
        New-PoshBotCardResponse -Type Normal -Text ($groups | Format-List | Out-String)
    }
}

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
        Aliases = ('gp', 'getpermission'),
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

function New-Group {
    <#
    .SYNOPSIS
        Create a new group.
    .PARAMETER Name
        The name of the group to create.
    .PARAMETER Description
        A short description for the group.
    .EXAMPLE
        !new-group servicedesk 'Service desk users'

        Create a new group called [sevicedesk].
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
        New-PoshBotCardResponse -Type Normal -Text "Group [$Name] created." -ThumbnailUrl $thumb.success
    } else {
        New-PoshBotCardResponse -Type Warning -Text "Group [$Name] could not be created. Check logs for more information." -ThumbnailUrl $thumb.warning
    }
}

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
        [string]$Name
    )

    if ($g = $Bot.RoleManager.GetGroup($Name)) {
        try {
            $Bot.RoleManager.RemoveGroup($g)
            New-PoshBotCardResponse -Type Normal -Text "Group [$Name] removed" -ThumbnailUrl $thumb.success
        } catch {
            New-PoshBotCardResponse -Type Error -Text "Failed to remove group [$Name]" -ThumbnailUrl $thumb.error
        }
    } else {
        New-PoshBotCardResponse -Type Warning -Text "Group [$Name] not found :(" -Title 'Rut row' -ThumbnailUrl $thumb.rutrow
    }
}

function Update-GroupDescription {
    <#
    .SYNOPSIS
        Update the description for a group.
    .PARAMETER Name
        The name of the group to update.
    .PARAMETER Description
        The new description for the group.
    .EXAMPLE
        !update-groupdescription servicedesk 'All Service Desk users'
    #>
    [PoshBot.BotCommand(
        Permissions = 'manage-groups'
    )]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Mandatory, Position = 0)]
        [string]$Name,

        [parameter(Mandatory, Position = 1)]
        [string]$Description
    )

    if ($g = $Bot.RoleManager.GetGroup($Name)) {
        try {
            $Bot.RoleManager.UpdateGroupDescription($Name, $Description)
            New-PoshBotCardResponse -Type Normal -Text "Group [$Name] description is now [$Description]" -ThumbnailUrl $thumb.success
        } catch {
            New-PoshBotCardResponse -Type Error -Text "Failed to update group [$Name]" -ThumbnailUrl $thumb.error
        }
    } else {
        New-PoshBotCardResponse -Type Warning -Text "Group [$Name] not found :(" -Title 'Rut row' -ThumbnailUrl $thumb.rutrow
    }
}

function New-Role {
    <#
    .SYNOPSIS
        Create a new role.
    .PARAMETER Name
        The name of the new role to create.
    .PARAMETER Description
        The description for the new role.
    .EXAMPLE
        !rew-role 'itsm-modify' 'Can modify items in ITSM tool'
    #>
    [PoshBot.BotCommand(
        Aliases = ('nr', 'newrole'),
        Permissions = 'manage-roles'
    )]
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
        New-PoshBotCardResponse -Type Normal -Text "Role [$Name] created." -ThumbnailUrl $thumb.success
    } else {
        New-PoshBotCardResponse -Type Warning -Text "Role [$Name] could not be created. Check logs for more information." -ThumbnailUrl $thumb.warning
    }
}

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
        [string]$Name
    )

    if ($r = $Bot.RoleManager.GetRole($Name)) {
        try {
            $Bot.RoleManager.RemoveRole($r)
            New-PoshBotCardResponse -Type Normal -Text "Role [$Name] removed" -ThumbnailUrl $thumb.success
        } catch {
            New-PoshBotCardResponse -Type Error -Text "Failed to remove role [$Name]" -ThumbnailUrl $thumb.error
        }
    } else {
        New-PoshBotCardResponse -Type Warning -Text "Role [$Name] not found :(" -Title 'Rut row' -ThumbnailUrl $thumb.rutrow
    }
}

function Update-RoleDescription {
    <#
    .SYNOPSIS
        Update a role description
    .PARAMETER Name
        The name of the role to update.
    .PARAMETER Description
        The new description for the role.
    .EXAMPLE
        !update-roledescription --name itsm-modify --description 'Can modify items in ITSM tool'
    #>
    [PoshBot.BotCommand(
        Permissions = 'manage-roles'
    )]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Mandatory, Position = 0)]
        [string]$Name,

        [parameter(Mandatory, Position = 1)]
        [string]$Description
    )

    if ($r = $Bot.RoleManager.GetRole($Name)) {
        try {
            $Bot.RoleManager.UpdateRoleDescription($Name, $Description)
            New-PoshBotCardResponse -Type Normal -Text "Role [$Name] description is now [$Description]" -ThumbnailUrl $thumb.success
        } catch {
            New-PoshBotCardResponse -Type Error -Text "Failed to update role [$Name]" -ThumbnailUrl $thumb.error
        }
    } else {
        New-PoshBotCardResponse -Type Warning -Text "Role [$Name] not found :(" -Title 'Rut row' -ThumbnailUrl $thumb.rutrow
    }
}

function Add-RolePermission {
    <#
    .SYNOPSIS
        Add a permission to a role.
    .PARAMETER Role
        The name of the role to add a permission to.
    .PARAMETER Permission
        The name of the permission to add to the role.
    .EXAMPLE
        !add-rolepermission --role 'itsm-modify' --permission 'itsm:create-ticket'

        Add the [itsm:create-ticket] permission to the [itsm-modify] role.
    #>
    [PoshBot.BotCommand(
        Permissions = 'manage-roles'
    )]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Mandatory, Position = 0)]
        [string]$Role,

        [parameter(Mandatory, Position = 1)]
        [string]$Permission
    )

    if ($r = $Bot.RoleManager.GetRole($Role)) {
        if ($p = $Bot.RoleManager.Permissions[$Permission]) {
            try {
                $Bot.RoleManager.AddPermissionToRole($Permission, $Role)
                New-PoshBotCardResponse -Type Normal -Text "Permission [$Permission] added to role [$Role]." -ThumbnailUrl $thumb.success
            } catch {
                New-PoshBotCardResponse -Type Error -Text "Failed to add [$Permission] to group [$Role]" -ThumbnailUrl $thumb.error
            }
        } else {
            New-PoshBotCardResponse -Type Warning -Text "Permission [$Permission] not found :(" -Title 'Rut row' -ThumbnailUrl $thumb.rutrow
        }
    } else {
        New-PoshBotCardResponse -Type Warning -Text "Role [$Role] not found :(" -Title 'Rut row' -ThumbnailUrl $thumb.rutrow
    }
}

function Remove-RolePermission {
    <#
    .SYNOPSIS
        Remove a permission from a role.
    .PARAMETER Role
        The name of the role to remove a permission from.
    .PARAMETER Permission
        The name of the permission to remove from the role.
    .EXAMPLE
        !remove-rolepermission --role 'itsm-modify' --permission 'itsm:create-ticket'

        Remove the [itsm:create-ticket] permission from the [itsm-modify] role.
    #>
    [PoshBot.BotCommand(
        Permissions = 'manage-roles'
    )]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Mandatory, Position = 0)]
        [string]$Role,

        [parameter(Mandatory, Position = 1)]
        [string]$Permission
    )

    if ($r = $Bot.RoleManager.GetRole($Role)) {
        if ($p = $Bot.RoleManager.Permissions[$Permission]) {
            try {
                $Bot.RoleManager.RemovePermissionFromRole($Permission, $Role)
                New-PoshBotCardResponse -Type Normal -Text "Permission [$Permission] removed from role [$role]." -ThumbnailUrl $thumb.success
            } catch {
                New-PoshBotCardResponse -Type Error -Text "Failed to remove [$Permission] from role [$role]" -ThumbnailUrl $thumb.error
            }
        } else {
            New-PoshBotCardResponse -Type Warning -Text "Permission [$Permission] not found :(" -Title 'Rut row' -ThumbnailUrl $thumb.rutrow
        }
    } else {
        New-PoshBotCardResponse -Type Warning -Text "Role [$Role] not found :(" -Title 'Rut row' -ThumbnailUrl $thumb.rutrow
    }
}

function Add-GroupUser {
    <#
    .SYNOPSIS
        Add a user to a group.
    .PARAMETER Group
        The name of the group to add a user to.
    .PARAMETER User
        The name of the user to add to a group.
    .EXAMPLE
        !add-groupuser --group admins --user johndoe
    #>
    [PoshBot.BotCommand(Permissions = 'manage-groups')]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Mandatory, Position = 0)]
        [string]$Group,

        [parameter(Mandatory, Position = 1)]
        [string]$User
    )

    if ($g = $Bot.RoleManager.GetGroup($Group)) {
        # Resolve username to user id
        if ($userId = $Bot.RoleManager.ResolveUserToId($User)) {
            try {
                $bot.RoleManager.AddUserToGroup($userId, $Group)
                New-PoshBotCardResponse -Type Normal -Text "User [$User] added to group [$Group]." -ThumbnailUrl $thumb.success
            } catch {
                New-PoshBotCardResponse -Type Error -Text "Failed to add [$User] to group [$Group]" -ThumbnailUrl $thumb.error
            }
        } else {
            New-PoshBotCardResponse -Type Warning -Text "User [$User] not found :(" -Title 'Rut row' -ThumbnailUrl $thumb.rutrow
        }
    } else {
        New-PoshBotCardResponse -Type Warning -Text "Group [$Group] not found :(" -Title 'Rut row' -ThumbnailUrl $thumb.rutrow
    }
}

function Remove-GroupUser {
    <#
    .SYNOPSIS
        Remove a user from a group.
    .PARAMETER Group
        The name of the group to remove a user from.
    .PARAMETER User
        The name of the user to remove from a group.
    .EXAMPLE
        !remove-groupuser --group admins --user johndoe
    #>
    [PoshBot.BotCommand(
        Permissions = 'manage-groups'
    )]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Mandatory, Position = 0)]
        [string]$Group,

        [parameter(Mandatory, Position = 1)]
        [string]$User
    )

    if ($g = $Bot.RoleManager.GetGroup($Group)) {
        if ($userId = $Bot.RoleManager.ResolveUserToId($User)) {
            try {
                $bot.RoleManager.RemoveUserFromGroup($userId, $Group)
                New-PoshBotCardResponse -Type Normal -Text "User [$User] removed from group [$Group]." -ThumbnailUrl $thumb.success
            } catch {
                New-PoshBotCardResponse -Type Error -Text "Failed to remove [$User] from group [$Group]" -ThumbnailUrl $thumb.error
            }
        } else {
            New-PoshBotCardResponse -Type Warning -Text "User [$User] not found :(" -Title 'Rut row' -ThumbnailUrl $thumb.rutrow
        }
    } else {
        New-PoshBotCardResponse -Type Warning -Text "Group [$Group] not found :(" -Title 'Rut row' -ThumbnailUrl $thumb.rutrow
    }
}

function Add-GroupRole {
    <#
    .SYNOPSIS
        Add a role to a group.
    .PARAMETER Group
        The name of the group to add a role to.
    .PARAMETER Role
        The name of the role to add to a group.
    .EXAMPLE
        !remove-grouprole --group servicedesk --role itsm-modify
    #>
    [PoshBot.BotCommand(
        Permissions = 'manage-groups'
    )]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Mandatory, Position = 0)]
        [string]$Group,

        [parameter(Mandatory, Position = 1)]
        [string]$Role
    )

    if ($g = $Bot.RoleManager.GetGroup($Group)) {
        if ($r = $Bot.RoleManager.GetRole($Role)) {
            try {
                $bot.RoleManager.AddRoleToGroup($Role, $Group)
                New-PoshBotCardResponse -Type Normal -Text "Role [$Role] added to group [$Group]." -ThumbnailUrl $thumb.success
            } catch {
                New-PoshBotCardResponse -Type Error -Text "Failed to add [$Role] to group [$Group]" -ThumbnailUrl $thumb.error
            }
        } else {
            New-PoshBotCardResponse -Type Warning -Text "Role [$Role] not found :(" -Title 'Rut row' -ThumbnailUrl $thumb.rutrow
        }
    } else {
        New-PoshBotCardResponse -Type Warning -Text "Group [$Group] not found :(" -Title 'Rut row' -ThumbnailUrl $thumb.rutrow
    }
}

function Remove-GroupRole {
    <#
    .SYNOPSIS
        Remove a role from a group.
    .PARAMETER Group
        The name of the group to remove a role from.
    .PARAMETER Role
        The name of the role to remove from a group.
    .EXAMPLE
        !remove-grouprole --group servicedesk --role itsm-modify
    #>
    [PoshBot.BotCommand(
        Permissions = 'manage-groups'
    )]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Mandatory, Position = 0)]
        [string]$Group,

        [parameter(Mandatory, Position = 1)]
        [string]$Role
    )

    if ($g = $Bot.RoleManager.GetGroup($Group)) {
        if ($r = $Bot.RoleManager.GetRole($Role)) {
            try {
                $bot.RoleManager.RemoveRoleFromGroup($Role, $Group)
                New-PoshBotCardResponse -Type Normal -Text "Role [$Role] removed from group [$Group]." -ThumbnailUrl $thumb.success
            } catch {
                New-PoshBotCardResponse -Type Error -Text "Failed to remove [$Role] from group [$Group]" -ThumbnailUrl $thumb.error
            }
        } else {
            New-PoshBotCardResponse -Type Warning -Text "Role [$Role] not found :(" -Title 'Rut row' -ThumbnailUrl $thumb.rutrow
        }
    } else {
        New-PoshBotCardResponse -Type Warning -Text "Group [$Group] not found :(" -Title 'Rut row' -ThumbnailUrl $thumb.rutrow
    }
}

function About {
    <#
    .SYNOPSIS
        Display details about PoshBot.
    .EXAMPLE
        !about
    #>
    [PoshBot.BotCommand(
        Permissions = 'view'
    )]
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

https://github.com/poshbotio/PoshBot
"@

    New-PoshBotTextResponse -Text $msg -AsCode
}

function Get-CommandHistory {
    <#
    .SYNOPSIS
        Get the recent execution history of a command
    .PARAMETER Name
        The command name to get history for.
    .PARAMETER Id
        Theh Id of the command execution to get details for.
    .PARAMETER Count
        The number of most recent history items to retrieve.
    .EXAMPLE
        !get-commandhistory

        Get all recent command history.
    .EXAMPLE
        !get-commandhistory --name 'status' --count 2

        Get the last 2 execution history entries for the [status] command.
    .EXAMPLE
        !get-commandhistory --id 5d337f17-bdc7-4f51-af0f-2629ac8224ce

        Get details about command exeuction Id [5d337f17-bdc7-4f51-af0f-2629ac8224ce].
    #>
    [PoshBot.BotCommand(
        Aliases = ('history'),
        Permissions = 'manage-plugins'
    )]
    [cmdletbinding(DefaultParameterSetName = 'all')]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Position = 0, ParameterSetName = 'name')]
        [string]$Name,

        [parameter(Position = 0, ParameterSetName = 'id')]
        [string]$Id,

        [parameter(Position = 0, ParameterSetName = 'all')]
        [parameter(Position = 1, ParameterSetName = 'name')]
        [parameter(Position = 1, ParameterSetName = 'id')]
        [int]$Count = 20
    )

    $shortProps = @(
        @{
            Label = 'Id'
            Expression = { $_.Id }
        }
        @{
            Label = 'Command'
            Expression = { $_.Command.Name }
        }
        @{
            Label = 'Caller'
            Expression = { $Bot.Backend.UserIdToUsername($_.Message.From) }
        }
        @{
            Label = 'Success'
            Expression = { $_.Result.Success }
        }
        @{
            Label = 'Started'
            Expression = { $_.Ended.ToString('u')}
        }
    )

    $longProps = $shortProps + @(
        @{
            Label = 'Duration'
            Expression = { $_.Result.Duration.TotalSeconds }
        }
        @{
            Label = 'CommandString'
            Expression = { $_.ParsedCommand.CommandString }
        }
    )

    $allHistory = $Bot.Executor.History | Sort-Object -Property Started -Descending

    # Array start from zero. Humans usually don't
    $Count = $Count - 1

    switch ($PSCmdlet.ParameterSetName) {
        'all' {
            $search = '*'
            $history = $allHistory
        }
        'name' {
            $search = $Name
            $history = @($allHistory | Where-Object {$_.Command.Name -eq $Name})[0..$Count]
        }
        'id' {
            $search = $Id
            $history = @($allHistory | Where-Object {$_.Id -eq $Id})[0..$Count]
        }
    }

    if ($history) {
        if ($history.Count -gt 1) {
            New-PoshBotCardResponse -Type Normal -Text ($history | Select-Object -Property $shortProps | Format-List | Out-String)
        } else {
            New-PoshBotCardResponse -Type Normal -Text ($history | Select-Object -Property $longProps | Format-List | Out-String)
        }
    } else {
        New-PoshBotCardResponse -Type Warning -Text "History for [$search] not found :(" -Title 'Rut row' -ThumbnailUrl $thumb.rutrow
    }
}

function Find-Plugin {
    <#
    .SYNOPSIS
        Find available PoshBot plugins. Only plugins (PowerShell modules) with the 'PoshBot' tag are returned.
    .PARAMETER NAME
        The name of the plugin (PowerShell module) to find. The module in the repository MUST have a 'PoshBot' tag.
    .PARAMETER Repository
        The name of the PowerShell repository to search in.
    .EXAMPLE
        !find-plugin

        Find all plugins with the 'PoshBot' tag.
    .EXAMPLE
        !find-plugin --name 'xkcd'

        Find all plugins matching '*xkcd*'
    .EXAMPLE
        !find-plugin --name 'itsm' --repository 'internalps'

        Find all plugins matching '*itsm*' in the 'internalps' repository.
    #>
    [PoshBot.BotCommand(Permissions = 'manage-plugins')]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Position = 0)]
        [string]$Name,

        [parameter(Position = 1)]
        [string]$Repository = 'PSGallery'
    )

    $params = @{
        Repository = $Repository
        Tag = 'poshbot'
    }
    if (-not [string]::IsNullOrEmpty($Name)) {
        $params.Name = "*$Name*"
    } else {
        $params.Filter = 'poshbot'
    }
    $plugins = @(Find-Module @params | Where-Object {$_.Name -ne 'Poshbot'} | Sort-Object -Property Name)

    if ($plugins) {
        if ($plugins.Count -eq 1) {
            $details = $plugins | Select-Object -Property 'Name', 'Description', 'Version', 'Author', 'CompanyName', 'Copyright', 'PublishedDate', 'ProjectUri', 'Tags'
            $cardParams = @{
                Type = 'Normal'
                Title = "Found [$($details.Name)] on [$Repository]"
                Text = ($details | Format-List -Property * | Out-String)
            }
            if (-not [string]::IsNullOrEmpty($details.IconUri)) {
                $cardParams.ThumbnailUrl = $details.IconUri
            }
            if (-not [string]::IsNullOrEmpty($details.ProjectUri)) {
                $cardParams.LinkUrl = $details.ProjectUri
            }
            New-PoshBotCardResponse @cardParams
        } else {
            New-PoshBotCardResponse -Type Normal -Title "Available PoshBot plugins on [$Repository]" -Text ($plugins | Format-Table -Property Name, Version, Description -AutoSize | Out-String)
        }
    } else {
        $notFoundParams = @{
            Type = 'Warning'
            Title = 'Terrible news'
            ThumbnailUrl = 'http://p1cdn05.thewrap.com/images/2015/06/don-draper-shrug.jpg'
        }
        if (-not [string]::IsNullOrEmpty($Name)) {
            $notFoundParams.Text = "No PoshBot plugins matching [$Name] where found in repository [$Repository]"
        } else {
            $notFoundParams.Text = "No PoshBot plugins where found in repository [$Repository]"
        }
        New-PoshBotCardResponse @notFoundParams
    }
}

function New-Permission {
    <#
    .SYNOPSIS
        Creates a new adhoc permission associated with a plugin.
    .PARAMETER Name
        The name of the new permission to create.
    .PARAMETER Plugin
        The name of the plugin in which to associate the permission to.
    .PARAMETER Description
        The description for the new permission.
    .EXAMPLE
        !new-permission --name read --plugin myplugin --description 'Execute all read commands'

        Create the [read] permission in the [myplugin] plugin.
    #>
    [PoshBot.BotCommand(Permissions = 'manage-permissions')]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Mandatory, Position = 0)]
        [string]$Name,

        [parameter(Mandatory, Position = 1)]
        [string]$Plugin,

        [parameter(Position = 2)]
        [string]$Description
    )

    if ($pluginVersions = $Bot.PluginManager.Plugins[$Plugin]) {

        # Get the latest version of the the plugin
        $latestPluginVersion = @($pluginVersions.Keys | Sort-Object -Descending)[0]

        # Create the adhoc permission
        $permission = [Permission]::New($Name, $Plugin)
        $permission.Adhoc = $true
        if ($PSBoundParameters.ContainsKey('Description')) {
            $permission.Description = $Description
        }

        if ($pv = $pluginVersions[$latestPluginVersion]) {
            # Assign permission to plugin and add to Role Manager
            $Bot.RoleManager.AddPermission($permission)
            $pv.AddPermission($permission)
            $Bot.PluginManager.Savestate()

            if ($p = $Bot.RoleManager.GetPermission($permission.ToString())) {
                New-PoshBotCardResponse -Type Normal -Text "Permission [$($permission.ToString())] created." -ThumbnailUrl $thumb.success
            } else {
                New-PoshBotCardResponse -Type Warning -Text "Permission [$($permission.ToString())] could not be created. Check logs for more information." -ThumbnailUrl $thumb.warning
            }
        } else {
            New-PoshBotCardResponse -Type Warning -Text "Unable to get latest version of plugin [$Plugin]."
        }
    } else {
        New-PoshBotCardResponse -Type Warning -Text "Plugin [$Plugin] not found."
    }
}

function Add-CommandPermission {
    <#
    .SYNOPSIS
        Adds a permission to a command.
    .PARAMETER Command
        The fully qualified command name [pluginname:commandname] to add the permission to.
    .PARAMETER Permission
        The fully qualified permission name [pluginname:permissionname] to add to the command.
    .EXAMPLE
        !add-commandpermission --command myplugin:mycommand --permission myplugin:read

        Add the permission [myplugin:read] to the [myplugin:mycommand] command.
    #>
    [PoshBot.BotCommand(Permissions = 'manage-permissions')]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Mandatory, Position = 0)]
        [ValidatePattern('^.+:.+')]
        [Alias('Name')]
        [string]$Command,

        [parameter(Mandatory, Position = 1)]
        [ValidatePattern('^.+:.+')]
        [string]$Permission
    )

    if ($c = $Bot.PluginManager.Commands[$Command]) {
        if ($p = $Bot.RoleManager.Permissions[$Permission]) {

            $c.AddPermission($p)
            $Bot.PluginManager.SaveState()

            New-PoshBotCardResponse -Type Normal -Text "Permission [$Permission] added to command [$Command]." -ThumbnailUrl $thumb.success
        } else {
            New-PoshBotCardResponse -Type Warning -Text "Permission [$Permission] not found."
        }
    } else {
        New-PoshBotCardResponse -Type Warning -Text "Command [$Command] not found."
    }
}

function Get-ScheduledCommand {
    <#
    .SYNOPSIS
        Get all scheduled commands.
    .PARAMETER Id
        The Id of the scheduled command to retrieve.
    .EXAMPLE
        !get-scheduledcommand

        List all scheduled commands
    .EXAMPLE !get-scheduledcommand --id e26b82cf473647e780041cee00a941de

        Get the scheduled command with Id [e26b82cf473647e780041cee00a941de]
    #>
    [PoshBot.BotCommand(
        Aliases = ('getschedule', 'get-schedule'),
        Permissions = 'manage-schedules'
    )]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [string]$Id
    )

    $fields = @(
        'Id',
        @{l='Command';e={$_.Message.Text}}
        @{l='Interval';e={"Every $($_.TimeValue) $($_.TimeInterval)"}}
        'TimesExecuted'
        @{l='StartAfter';e={$_.StartAfter.ToString('u')}}
        'Enabled'
    )

    if ($Id) {
        if ($schedule = $Bot.Scheduler.GetSchedule($Id)) {
            $msg = ($schedule | Select-Object -Property $fields | Format-List | Out-String).Trim()
            New-PoshBotTextResponse -Text $msg -AsCode
        } else {
            New-PoshBotCardResponse -Type Warning -Text "Scheduled command [$Id] not found." -ThumbnailUrl $thumb.warning
        }
    } else {
        $schedules = $Bot.Scheduler.ListSchedules()
        if ($schedules.Count -gt 0) {
            $msg = ($schedules | Select-Object -Property $fields | Format-Table -AutoSize | Out-String).Trim()
            New-PoshBotTextResponse -Text $msg -AsCode
        } else {
            New-PoshBotTextResponse -Text 'There are no commands scheduled'
        }
    }
}

function New-ScheduledCommand {
    <#
    .SYNOPSIS
        Create a new scheduled command.
    .PARAMETER Command
        The command string to schedule. This will be in the form of '!foo --bar baz' just like you would
        type interactively.
    .PARAMETER Value
        Execute the command after the specified number of intervals (e.g., 2 hours).
    .PARAMETER Interval
        The interval in which to schedule the command. The valid values are 'days', 'hours', 'minutes', and 'seconds'.
    .PARAMETER StartAfter
        Start the scheduled command exeuction after this date/time.
    .PARAMETER Once
        Execute the scheduled command once and then remove the schedule.
        This parameter is not valid with the Interval and Value parameters.
    .EXAMPLE
        !new-scheduledcommand --command 'status' --interval hours --value 4

        Execute the [status] command every 4 hours.
    .EXAMPLE
        !new-scheduledcommand --command !myplugin:motd' --interval days --value 1 --startafter '8:00am'

        Execute the command [myplugin:motd] every day starting at 8:00am.
    .EXAMPLE
        !new-scheduledcommand --command "!myplugin:restart-server --computername frodo --startafter '2016/07/04 6:00pm'" --once

        Execute the command [restart-server] on computername [frodo] at 6:00pm on 2016/07/04.
    #>
    [PoshBot.BotCommand(
        Aliases = ('newschedule', 'new-schedule'),
        Permissions = 'manage-schedules'
    )]
    [cmdletbinding(DefaultParameterSetName = 'repeat')]
    param(
        [parameter(Mandatory, ParameterSetName = 'repeat')]
        [parameter(Mandatory, ParameterSetName = 'once')]
        $Bot,

        [parameter(Mandatory, Position = 0, ParameterSetName = 'repeat')]
        [parameter(Mandatory, Position = 0, ParameterSetName = 'once')]
        [ValidateNotNullOrEmpty()]
        [string]$Command,

        [parameter(Mandatory, Position = 1, ParameterSetName = 'repeat')]
        [ValidateNotNull()]
        [int]$Value,

        [parameter(Mandatory, Position = 2, ParameterSetName = 'repeat')]
        [ValidateSet('days', 'hours', 'minutes', 'seconds')]
        [ValidateNotNullOrEmpty()]
        [string]$Interval,

        [parameter(ParameterSetName = 'repeat')]
        [parameter(Mandatory, ParameterSetName = 'once')]
        [ValidateScript({
            if ($_ -as [datetime]) {
                return $true
            } else {
                throw '''StartAfter'' must be a datetime.'
            }
        })]
        [string]$StartAfter,

        [parameter(Mandatory, ParameterSetName = 'once')]
        [switch]$Once
    )

    if (-not $Command.StartsWith($Bot.Configuration.CommandPrefix)) {
        $Command = $Command.Insert(0, $Bot.Configuration.CommandPrefix)
    }

    $botMsg = [Message]::new()
    $botMsg.Text = $Command
    $botMsg.From = $global:PoshBotContext.From
    $botMsg.To = $global:PoshBotContext.To

    if ($PSCmdlet.ParameterSetName -eq 'repeat') {
        # This command will be executed on a schedule with an optional time to start the interval
        if ($PSBoundParameters.ContainsKey('StartAfter')) {
            $schedMsg = [ScheduledMessage]::new($Interval, $value, $botMsg, [datetime]$StartAfter)
        } else {
            $schedMsg = [ScheduledMessage]::new($Interval, $value, $botMsg)
        }
    } elseIf ($PSCmdlet.ParameterSetName -eq 'once') {
        # This command will be executed once then removed from the scheduler
        $schedMsg = [ScheduledMessage]::new($botMsg, [datetime]$StartAfter)
    }

    try {
        $Bot.Scheduler.ScheduleMessage($schedMsg)

        if ($PSCmdlet.ParameterSetName -eq 'repeat') {
            New-PoshBotCardResponse -Type Normal -Text "Command [$Command] scheduled at interval [$Value $($Interval.ToLower())]." -ThumbnailUrl $thumb.success
        } elseIf ($PSCmdlet.ParameterSetName -eq 'once') {
            New-PoshBotCardResponse -Type Normal -Text "Command [$Command] scheduled for one time at [$([datetime]$StartAfter)]." -ThumbnailUrl $thumb.success
        }
    } catch {
        New-PoshBotCardResponse -Type Error -Text $_.ToString() -ThumbnailUrl $thumb.error
    }
}

function Set-ScheduledCommand {
    <#
    .SYNOPSIS
        Modify a scheduled command.
    .PARAMETER Id
        The Id of the scheduled command to edit.
    .PARAMETER Value
        Execute the command after the specified number of intervals (e.g., 2 hours).
    .PARAMETER Inteval
        The interval in which to schedule the command. The valid values are 'days', 'hours', 'minutes', and 'seconds'.
    .PARAMETER StartAfter
        Start the scheduled command exeuction after this date/time.
    .EXAMPLE
        !set-scheduledcommand --id e26b82cf473647e780041cee00a941de --value 2 --interval days

        Edit the existing scheduled command with Id [e26b82cf473647e780041cee00a941de] and set the
        repetition interval to every 2 days.
    .EXAMPLE
        !set-scheduledcommand --id ccef0790b94542a685e78b4ec50c8c1e --value 1 --interval hours --startafter '10:00pm'

        Edit the existing scheduled command with Id [ccef0790b94542a685e78b4ec50c8c1e] and set the
        repition interval to every hours starting at 10:00pm.
    #>
    [PoshBot.BotCommand(
        Aliases = ('setschedule', 'set-schedule'),
        Permissions = 'manage-schedules'
    )]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Mandatory, Position = 0)]
        [string]$Id,

        [parameter(Mandatory, Position = 1)]
        [ValidateNotNull()]
        [int]$Value,

        [parameter(Mandatory, Position = 2)]
        [ValidateSet('days', 'hours', 'minutes', 'seconds')]
        [ValidateNotNullOrEmpty()]
        [string]$Interval,

        [ValidateScript({
            if ($_ -as [datetime]) {
                return $true
            } else {
                throw '''StartAfter'' must be a datetime.'
            }
        })]
        [string]$StartAfter
    )

    if ($scheduledMessage = $Bot.Scheduler.GetSchedule($Id)) {
        $scheduledMessage.TimeInterval = $Interval
        $scheduledMessage.TimeValue = $Value
        if ($PSBoundParameters.ContainsKey('StartAfter')) {
            $scheduledMessage.StartAfter = [datetime]$StartAfter
        }
        $scheduledMessage = $bot.Scheduler.SetSchedule($scheduledMessage)
        New-PoshBotCardResponse -Type Normal -Text "Schedule for command [$($scheduledMessage.Message.Text)] changed to every [$Value $($Interval.ToLower())]." -ThumbnailUrl $thumb.success
    } else {
        New-PoshBotCardResponse -Type Warning -Text "Scheduled command [$Id] not found." -ThumbnailUrl $thumb.warning
    }
}

function Remove-ScheduledCommand {
    <#
    .SYNOPSIS
        Remove a scheduled command.
    .PARAMETER Id
        The Id of the scheduled command to remove.
    .EXAMPLE
        !remove-scheduledcommand --id 1fb032bdec82423ba763227c83ca2c89

        Remove the scheduled command with id [1fb032bdec82423ba763227c83ca2c89].
    #>
    [PoshBot.BotCommand(
        Aliases = 'removeschedule', ('remove-schedule'),
        Permissions = 'manage-schedules'
    )]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Id
    )

    if ($Bot.Scheduler.GetSchedule($Id)) {
        $Bot.Scheduler.RemoveScheduledMessage($Id)
        $msg = "Schedule Id [$Id] removed"
        New-PoshBotCardResponse -Type Normal -Text $msg -ThumbnailUrl $thumb.success
    } else {
        New-PoshBotCardResponse -Type Warning -Text "Scheduled command [$Id] not found." -ThumbnailUrl $thumb.warning
    }
}

function Enable-ScheduledCommand {
    <#
    .SYNOPSIS
        Enable a scheduled command.
    .PARAMETER Id
        The Id of the scheduled command to enable.
    .EXAMPLE
        !enable-scheduledcommand --id a993c0880b184de098f46d8bbc81436b

        Enable the scheduled command with id [a993c0880b184de098f46d8bbc81436b].
    #>
    [PoshBot.BotCommand(
        Aliases = ('enableschedule', 'enable-schedule'),
        Permissions = 'manage-schedules'
    )]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Id
    )

    if ($Bot.Scheduler.GetSchedule($Id)) {
        $scheduledMessage = $Bot.Scheduler.EnableSchedule($Id)
        $fields = @(
            'Id'
            @{l='Command'; e = {$_.Message.Text}}
            @{l='Interval'; e = {$_.TimeInterval}}
            @{l='Value'; e = {$_.TimeValue}}
            'TimesExecuted'
            @{l='StartAfter';e={_.StartAfter.ToString('s')}}
            'Enabled'
        )
        $msg = "Schedule for command [$($scheduledMessage.Message.Text)] enabled`n"
        $msg += ($scheduledMessage | Select-Object -Property $fields | Format-List | Out-String).Trim()
        New-PoshBotCardResponse -Type Normal -Text $msg -ThumbnailUrl $thumb.success
    } else {
        New-PoshBotCardResponse -Type Warning -Text "Scheduled command [$Id] not found." -ThumbnailUrl $thumb.warning
    }
}

function Disable-ScheduledCommand {
    <#
    .SYNOPSIS
        Disable a scheduled command.
    .PARAMETER Id
        The Id of the scheduled command to disable.
    .EXAMPLE
        !disable-scheduledcommand --id 2979f9961a0c4dea9fa6ea073a281e35

        Disable the scheduled command with id [2979f9961a0c4dea9fa6ea073a281e35].
    #>
    [PoshBot.BotCommand(
        Aliases = 'disableschedule',
        Permissions = 'manage-schedules'
    )]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Id
    )

    if ($Bot.Scheduler.GetSchedule($Id)) {
        $scheduledMessage = $Bot.Scheduler.DisableSchedule($Id)
        $fields = @(
            'Id'
            @{l='Command'; e = {$_.Message.Text}}
            @{l='Interval'; e = {$_.TimeInterval}}
            @{l='Value'; e = {$_.TimeValue}}
            'TimesExecuted'
            @{l='StartAfter';e={_.StartAfter.ToString('s')}}
            'Enabled'
        )
        $msg =  "Schedule for command [$($scheduledMessage.Message.Text)] disabled`n"
        $msg += ($scheduledMessage | Select-Object -Property $fields | Format-List | Out-String).Trim()
        New-PoshBotCardResponse -Type Normal -Text $msg -ThumbnailUrl $thumb.success
    } else {
        New-PoshBotCardResponse -Type Warning -Text "Scheduled command [$Id] not found." -ThumbnailUrl $thumb.warning
    }
}
