
class PluginManager : BaseLogger {

    [hashtable]$Plugins = @{}
    [hashtable]$Commands = @{}
    hidden [string]$_PoshBotModuleDir
    [RoleManager]$RoleManager
    [StorageProvider]$_Storage

    PluginManager([RoleManager]$RoleManager, [StorageProvider]$Storage, [Logger]$Logger, [string]$PoshBotModuleDir) {
        $this.RoleManager = $RoleManager
        $this._Storage = $Storage
        $this.Logger = $Logger
        $this._PoshBotModuleDir = $PoshBotModuleDir
        $this.Initialize()
    }

    # Initialize the plugin manager
    [void]Initialize() {
        $this.LogInfo('Initializing')
        $this.LoadState()
        $this.LoadBuiltinPlugins()
    }

    # Get the list of plugins to load and... wait for it... load them
    [void]LoadState() {
        $this.LogVerbose('Loading plugin state from storage')

        $pluginsToLoad = $this._Storage.GetConfig('plugins')
        if ($pluginsToLoad) {
            foreach ($pluginKey in $pluginsToLoad.Keys) {
                $pluginToLoad = $pluginsToLoad[$pluginKey]

                $pluginVersions = $pluginToLoad.Keys
                foreach ($pluginVersionKey in $pluginVersions) {
                    $pv = $pluginToLoad[$pluginVersionKey]
                    $manifestPath = $pv.ManifestPath
                    $adhocPermissions = $pv.AdhocPermissions
                    $this.CreatePluginFromModuleManifest($pluginKey, $manifestPath, $true, $false)

                    if ($newPlugin = $this.Plugins[$pluginKey]) {
                        # Add adhoc permissions back to plugin (all versions)
                        foreach ($version in $newPlugin.Keys) {
                            $npv = $newPlugin[$version]
                            foreach($permission in $adhocPermissions) {
                                if ($p = $this.RoleManager.GetPermission($permission)) {
                                    $npv.AddPermission($p)
                                }
                            }

                            # Add adhoc permissions back to the plugin commands (all versions)
                            $commandPermissions = $pv.CommandPermissions
                            foreach ($commandName in $commandPermissions.Keys ) {
                                $permissions = $commandPermissions[$commandName]
                                foreach ($permission in $permissions) {
                                    if ($p = $this.RoleManager.GetPermission($permission)) {
                                        $npv.AddPermission($p)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    # Save the state of currently loaded plugins to storage
    [void]SaveState() {
        $this.LogVerbose('Saving loaded plugin state to storage')

        # Skip saving builtin plugin as it will always be loaded at initialization
        $pluginsToSave = @{}
        foreach($pluginKey in $this.Plugins.Keys | Where-Object {$_ -ne 'Builtin'}) {
            $versions = @{}
            foreach ($versionKey in $this.Plugins[$pluginKey].Keys) {
                $pv = $this.Plugins[$pluginKey][$versionKey]
                $versions.Add($versionKey, $pv.ToHash())
            }
            $pluginsToSave.Add($pluginKey, $versions)
        }
        $this._Storage.SaveConfig('plugins', $pluginsToSave)
    }

    # TODO
    # Given a PowerShell module definition, inspect it for commands etc,
    # create a plugin instance and load the plugin
    [void]InstallPlugin([string]$ManifestPath, [bool]$SaveAfterInstall = $false) {
        if (Test-Path -Path $ManifestPath) {
            $moduleName = (Get-Item -Path $ManifestPath).BaseName
            $this.CreatePluginFromModuleManifest($moduleName, $ManifestPath, $true, $SaveAfterInstall)
        } else {
            $msg = "Module manifest path [$manifestPath] not found"
            $this.LogInfo([LogSeverity]::Warning, $msg)
        }
    }

    # Add a plugin to the bot
    [void]AddPlugin([Plugin]$Plugin, [bool]$SaveAfterInstall = $false) {
        if (-not $this.Plugins.ContainsKey($Plugin.Name)) {
            $this.LogInfo("Attaching plugin [$($Plugin.Name)]")

            $pluginVersion = @{
                ($Plugin.Version).ToString() = $Plugin
            }
            $this.Plugins.Add($Plugin.Name, $pluginVersion)

            # Register the plugins permission set with the role manager
            foreach ($permission in $Plugin.Permissions.GetEnumerator()) {
                $this.LogVerbose("Adding permission [$($permission.Value.ToString())] to Role Manager")
                $this.RoleManager.AddPermission($permission.Value)
            }
        } else {
            if (-not $this.Plugins[$Plugin.Name].ContainsKey($Plugin.Version)) {
                # Install a new plugin version
                $this.LogInfo("Attaching version [$($Plugin.Version)] of plugin [$($Plugin.Name)]")
                $this.Plugins[$Plugin.Name].Add($Plugin.Version.ToString(), $Plugin)

                # Register the plugins permission set with the role manager
                foreach ($permission in $Plugin.Permissions.GetEnumerator()) {
                    $this.LogVerbose("Adding permission [$($permission.Value.ToString())] to Role Manager")
                    $this.RoleManager.AddPermission($permission.Value)
                }
            } else {
                $msg = "Plugin [$($Plugin.Name)] version [$($Plugin.Version)] is already loaded"
                $this.LogInfo([LogSeverity]::Warning, $msg)
                throw [PluginException]::New($msg)
            }
        }

        # # Reload commands and role from all currently loading (and active) plugins
        $this.LoadCommands()

        if ($SaveAfterInstall) {
            $this.SaveState()
        }
    }

    # Remove a plugin from the bot
    [void]RemovePlugin([Plugin]$Plugin) {
        if ($this.Plugins.ContainsKey($Plugin.Name)) {
            $pluginVersions = $this.Plugins[$Plugin.Name]
            if ($pluginVersions.Keys.Count -eq 1) {
                # Remove the permissions for this plugin from the role manaager
                # but only if this is the only version of the plugin loaded
                foreach ($permission in $Plugin.Permissions.GetEnumerator()) {
                    $this.LogVerbose("Removing permission [$($Permission.Value.ToString())]. No longer in use")
                    $this.RoleManager.RemovePermission($Permission.Value)
                }
                $this.LogInfo("Removing plugin [$($Plugin.Name)]")
                $this.Plugins.Remove($Plugin.Name)

                # Unload the PS module
                $moduleSpec = @{
                    ModuleName = $Plugin.Name
                    ModuleVersion = $pluginVersions
                }
                Remove-Module -FullyQualifiedName $moduleSpec -Verbose:$false -Force
            } else {
                if ($pluginVersions.ContainsKey($Plugin.Version)) {
                    $this.LogInfo("Removing plugin [$($Plugin.Name)] version [$($Plugin.Version)]")
                    $pluginVersions.Remove($Plugin.Version)

                    # Unload the PS module
                    $moduleSpec = @{
                        ModuleName = $Plugin.Name
                        ModuleVersion = $Plugin.Version
                    }
                    Remove-Module -FullyQualifiedName $moduleSpec -Verbose:$false -Force
                } else {
                    $msg = "Plugin [$($Plugin.Name)] version [$($Plugin.Version)] is not loaded in bot"
                    $this.LogInfo([LogSeverity]::Warning, $msg)
                    throw [PluginNotFoundException]::New($msg)
                }
            }
        }

        # Reload commands from all currently loading (and active) plugins
        $this.LoadCommands()

        $this.SaveState()
    }

    # Remove a plugin and optionally a specific version from the bot
    # If there is only one version, then remove any permissions defined in the plugin as well
    [void]RemovePlugin([string]$PluginName, [string]$Version) {
        if ($p = $this.Plugins[$PluginName]) {
            if ($pv = $p[$Version]) {
                if ($p.Keys.Count -eq 1) {
                    # Remove the permissions for this plugin from the role manaager
                    # but only if this is the only version of the plugin loaded
                    foreach ($permission in $pv.Permissions.GetEnumerator()) {
                        $this.LogVerbose("Removing permission [$($Permission.Value.ToString())]. No longer in use")
                        $this.RoleManager.RemovePermission($Permission.Value)
                    }
                    $this.LogInfo("Removing plugin [$($pv.Name)]")
                    $this.Plugins.Remove($pv.Name)
                } else {
                    $this.LogInfo("Removing plugin [$($pv.Name)] version [$Version]")
                    $p.Remove($pv.Version.ToString())
                }

                # Unload the PS module
                $unloadModuleParams = @{
                    FullyQualifiedName = @{
                        ModuleName    = $PluginName
                        ModuleVersion = $Version
                    }
                    Verbose = $false
                    Force   = $true
                }
                $this.LogDebug("Unloading module [$PluginName] version [$Version]")
                Remove-Module @unloadModuleParams
            } else {
                $msg = "Plugin [$PluginName] version [$Version] is not loaded in bot"
                $this.LogInfo([LogSeverity]::Warning, $msg)
                throw [PluginNotFoundException]::New($msg)
            }
        } else {
            $msg = "Plugin [$PluginName] is not loaded in bot"
            $this.LogInfo([LogSeverity]::Warning, $msg)
            throw [PluginNotFoundException]::New()
        }

        # Reload commands from all currently loading (and active) plugins
        $this.LoadCommands()

        $this.SaveState()
    }

    # Activate a plugin
    [void]ActivatePlugin([string]$PluginName, [string]$Version) {
        if ($p = $this.Plugins[$PluginName]) {
            if ($pv = $p[$Version]) {
                $this.LogInfo("Activating plugin [$PluginName] version [$Version]")
                $pv.Activate()

                # Reload commands from all currently loading (and active) plugins
                $this.LoadCommands()
                $this.SaveState()
            } else {
                $msg = "Plugin [$PluginName] version [$Version] is not loaded in bot"
                $this.LogInfo([LogSeverity]::Warning, $msg)
                throw [PluginNotFoundException]::New($msg)
            }
        } else {
            $msg = "Plugin [$PluginName] is not loaded in bot"
            $this.LogInfo([LogSeverity]::Warning, $msg)
            throw [PluginNotFoundException]::New()
        }
    }

    # Activate a plugin
    [void]ActivatePlugin([Plugin]$Plugin) {
        $p = $this.Plugins[$Plugin.Name]
        if ($p) {
            if ($pv = $p[$Plugin.Version.ToString()]) {
                $this.LogInfo("Activating plugin [$($Plugin.Name)] version [$($Plugin.Version)]")
                $pv.Activate()
            }
        } else {
            $msg = "Plugin [$($Plugin.Name)] version [$($Plugin.Version)] is not loaded in bot"
            $this.LogInfo([LogSeverity]::Warning, $msg)
            throw [PluginNotFoundException]::New($msg)
        }

        # Reload commands from all currently loading (and active) plugins
        $this.LoadCommands()

        $this.SaveState()
    }

    # Deactivate a plugin
    [void]DeactivatePlugin([Plugin]$Plugin) {
        $p = $this.Plugins[$Plugin.Name]
        if ($p) {
            if ($pv = $p[$Plugin.Version.ToString()]) {
                $this.LogInfo("Deactivating plugin [$($Plugin.Name)] version [$($Plugin.Version)]")
                $pv.Deactivate()
            }
        } else {
            $msg = "Plugin [$($Plugin.Name)] version [$($Plugin.Version)] is not loaded in bot"
            $this.LogInfo([LogSeverity]::Warning, $msg)
            throw [PluginNotFoundException]::New($msg)
        }

        # # Reload commands from all currently loading (and active) plugins
        $this.LoadCommands()

        $this.SaveState()
    }

    # Deactivate a plugin
    [void]DeactivatePlugin([string]$PluginName, [string]$Version) {
        if ($p = $this.Plugins[$PluginName]) {
            if ($pv = $p[$Version]) {
                $this.LogInfo("Deactivating plugin [$PluginName)] version [$Version]")
                $pv.Deactivate()

                # Reload commands from all currently loading (and active) plugins
                $this.LoadCommands()
                $this.SaveState()
            } else {
                $msg = "Plugin [$PluginName] version [$Version] is not loaded in bot"
                $this.LogInfo([LogSeverity]::Warning, $msg)
                throw [PluginNotFoundException]::New($msg)
            }
        } else {
            $msg = "Plugin [$PluginName] is not loaded in bot"
            $this.LogInfo([LogSeverity]::Warning, $msg)
            throw [PluginNotFoundException]::New($msg)
        }
    }

    # Match a parsed command to a command in one of the currently loaded plugins
    [PluginCommand]MatchCommand([ParsedCommand]$ParsedCommand, [bool]$CommandSearch = $true) {

        # Check builtin commands first
        $builtinKey = $this.Plugins['Builtin'].Keys | Select-Object -First 1
        $builtinPlugin = $this.Plugins['Builtin'][$builtinKey]
        foreach ($commandKey in $builtinPlugin.Commands.Keys) {
            $command = $builtinPlugin.Commands[$commandKey]
            if ($command.TriggerMatch($ParsedCommand, $CommandSearch)) {
                $this.LogInfo("Matched parsed command [$($ParsedCommand.Plugin)`:$($ParsedCommand.Command)] to builtin command [Builtin:$commandKey]")
                return [PluginCommand]::new($builtinPlugin, $command)
            }
        }

        # If parsed command is fully qualified with <plugin:command> syntax. Just look in that plugin
        if (($ParsedCommand.Plugin -ne [string]::Empty) -and ($ParsedCommand.Command -ne [string]::Empty)) {
            $plugin = $this.Plugins[$ParsedCommand.Plugin]
            if ($plugin) {
                if ($ParsedCommand.Version) {
                    # User specified a specific version of the plugin so get that one
                    $pluginVersion = $plugin[$ParsedCommand.Version]
                } else {
                    # Just look in the latest version of the plugin.
                    $latestVersionKey = $plugin.Keys | Sort-Object -Descending | Select-Object -First 1
                    $pluginVersion = $plugin[$latestVersionKey]
                }

                if ($pluginVersion) {
                    foreach ($commandKey in $pluginVersion.Commands.Keys) {
                        $command = $pluginVersion.Commands[$commandKey]
                        if ($command.TriggerMatch($ParsedCommand, $CommandSearch)) {
                            $this.LogInfo("Matched parsed command [$($ParsedCommand.Plugin)`:$($ParsedCommand.Command)] to plugin command [$($plugin.Name)`:$commandKey]")
                            return [PluginCommand]::new($pluginVersion, $command)
                        }
                    }
                }

                $this.LogInfo([LogSeverity]::Warning, "Unable to match parsed command [$($ParsedCommand.Plugin)`:$($ParsedCommand.Command)] to a command in plugin [$($plugin.Name)]")
            } else {
                $this.LogInfo([LogSeverity]::Warning, "Unable to match parsed command [$($ParsedCommand.Plugin)`:$($ParsedCommand.Command)] to a plugin command")
                return $null
            }
        } else {
            # Check all regular plugins/commands now
            foreach ($pluginKey in $this.Plugins.Keys) {
                $plugin = $this.Plugins[$pluginKey]
                $pluginVersion = $null
                if ($ParsedCommand.Version) {
                    # User specified a specific version of the plugin so get that one
                    $pluginVersion = $plugin[$ParsedCommand.Version]
                    foreach ($commandKey in $pluginVersion.Commands.Keys) {
                        $command = $pluginVersion.Commands[$commandKey]
                        if ($command.TriggerMatch($ParsedCommand, $CommandSearch)) {
                            $this.LogInfo("Matched parsed command [$($ParsedCommand.Plugin)`:$($ParsedCommand.Command)] to plugin command [$pluginKey`:$commandKey]")
                            return [PluginCommand]::new($pluginVersion, $command)
                        }
                    }
                } else {
                    # Just look in the latest version of the plugin.
                    foreach ($pluginVersionKey in $plugin.Keys | Sort-Object -Descending | Select-Object -First 1) {
                        $pluginVersion = $plugin[$pluginVersionKey]
                        foreach ($commandKey in $pluginVersion.Commands.Keys) {
                            $command = $pluginVersion.Commands[$commandKey]
                            if ($command.TriggerMatch($ParsedCommand, $CommandSearch)) {
                                $this.LogInfo("Matched parsed command [$($ParsedCommand.Plugin)`:$($ParsedCommand.Command)] to plugin command [$pluginKey`:$commandKey]")
                                return [PluginCommand]::new($pluginVersion, $command)
                            }
                        }
                    }
                }
            }
        }

        $this.LogInfo([LogSeverity]::Warning, "Unable to match parsed command [$($ParsedCommand.Plugin)`:$($ParsedCommand.Command)] to a plugin command")
        return $null
    }

    # Load in the available commands from all the loaded plugins
    [void]LoadCommands() {
        $allCommands = New-Object System.Collections.ArrayList
        foreach ($pluginKey in $this.Plugins.Keys) {
            $plugin = $this.Plugins[$pluginKey]

            foreach ($pluginVersionKey in $plugin.Keys | Sort-Object -Descending | Select-Object -First 1) {
                $pluginVersion = $plugin[$pluginVersionKey]
                if ($pluginVersion.Enabled) {
                    foreach ($commandKey in $pluginVersion.Commands.Keys) {
                        $command =  $pluginVersion.Commands[$commandKey]
                        $fullyQualifiedCommandName = "$pluginKey`:$CommandKey`:$pluginVersionKey"
                        $allCommands.Add($fullyQualifiedCommandName)
                        if (-not $this.Commands.ContainsKey($fullyQualifiedCommandName)) {
                            $this.LogVerbose("Loading command [$fullyQualifiedCommandName]")
                            $this.Commands.Add($fullyQualifiedCommandName, $command)
                        }
                    }
                }
            }
        }

        # Remove any commands that are not in any of the loaded (and active) plugins
        $remove = New-Object System.Collections.ArrayList
        foreach($c in $this.Commands.Keys) {
            if (-not $allCommands.Contains($c)) {
                $remove.Add($c)
            }
        }
        $remove | ForEach-Object {
            $this.LogVerbose("Removing command [$_]. Plugin has either been removed or is deactivated.")
            $this.Commands.Remove($_)
        }
    }

    # Create a new plugin from a given module manifest
    [void]CreatePluginFromModuleManifest([string]$ModuleName, [string]$ManifestPath, [bool]$AsJob = $true, [bool]$SaveAfterCreation = $false) {
        $manifest = Import-PowerShellDataFile -Path $ManifestPath -ErrorAction SilentlyContinue
        if ($manifest) {
            $this.LogInfo("Creating new plugin [$ModuleName]")
            $plugin = [Plugin]::new($this.Logger)
            $plugin.Name = $ModuleName
            $plugin._ManifestPath = $ManifestPath
            if ($manifest.ModuleVersion) {
                $plugin.Version = $manifest.ModuleVersion
            } else {
                $plugin.Version = '0.0.0'
            }

            # Load our plugin config
            $pluginConfig = $this.GetPluginConfig($plugin.Name, $plugin.Version)

            # Create new permissions from metadata in the module manifest
            $this.GetPermissionsFromModuleManifest($manifest) | ForEach-Object {
                $_.Plugin = $plugin.Name
                $plugin.AddPermission($_)
            }

            # Add any adhoc permissions that were previously defined back to the plugin
            if ($pluginConfig -and $pluginConfig.AdhocPermissions.Count -gt 0) {
                foreach ($permissionName in $pluginConfig.AdhocPermissions) {
                    if ($p = $this.RoleManager.GetPermission($permissionName)) {
                        $this.LogDebug("Adding adhoc permission [$permissionName] to plugin [$($plugin.Name)]")
                        $plugin.AddPermission($p)
                    } else {
                        $this.LogInfo([LogSeverity]::Warning, "Adhoc permission [$permissionName] not found in Role Manager. Can't attach permission to plugin [$($plugin.Name)]")
                    }
                }
            }

            # Add the plugin so the roles can be registered with the role manager
            $this.AddPlugin($plugin, $SaveAfterCreation)

            # Get exported cmdlets/functions from the module and add them to the plugin
            # Adjust bot command behaviour based on metadata as appropriate
            Import-Module -Name $ManifestPath -Scope Local -Verbose:$false -WarningAction SilentlyContinue -Force
            $moduleCommands = Microsoft.PowerShell.Core\Get-Command -Module $ModuleName -CommandType @('Cmdlet', 'Function') -Verbose:$false
            foreach ($command in $moduleCommands) {

                # Get any command metadata that may be attached to the command
                # via the PoshBot.BotCommand extended attribute
                # NOTE: This only works on functions, not cmdlets
                if ($command.CommandType -eq 'Function') {
                    $metadata = $this.GetCommandMetadata($command)
                } else {
                    $metadata = $null
                }

                $this.LogVerbose("Creating command [$($command.Name)] for new plugin [$($plugin.Name)]")
                $cmd                        = [Command]::new()
                $cmd.Name                   = $command.Name
                $cmd.ModuleQualifiedCommand = "$ModuleName\$($command.Name)"
                $cmd.ManifestPath           = $ManifestPath
                $cmd.Logger                 = $this.Logger
                $cmd.AsJob                  = $AsJob

                if ($command.CommandType -eq 'Function') {
                    $cmd.FunctionInfo = $command
                } elseIf ($command.CommandType -eq 'Cmdlet') {
                    $cmd.CmdletInfo = $command
                }

                # Triggers that will be added to the command
                $triggers = @()

                # Set command properties based on metadata from module
                if ($metadata) {

                    # Set the command name to what is defined in the metadata
                    if ($metadata.CommandName) {
                        $cmd.Name = $metadata.CommandName
                    }

                    # Add any alternate command names as aliases to the command
                    if ($metadata.Aliases) {
                        $metadata.Aliases | Foreach-Object {
                            $cmd.Aliases += $_
                            $triggers += [Trigger]::new([TriggerType]::Command, $_)
                        }
                    }

                    # Add any permissions defined within the plugin to the command
                    if ($metadata.Permissions) {
                        foreach ($item in $metadata.Permissions) {
                            $fqPermission = "$($plugin.Name):$($item)"
                            if ($p = $plugin.GetPermission($fqPermission)) {
                                $cmd.AddPermission($p)
                            } else {
                                $this.LogInfo([LogSeverity]::Warning, "Permission [$fqPermission] is not defined in the plugin module manifest. Command will not be added to plugin.")
                                continue
                            }
                        }
                    }

                    # Add any adhoc permissions that we may have been added in the past
                    # that is stored in our plugin configuration
                    if ($pluginConfig) {
                        foreach ($permissionName in $pluginConfig.AdhocPermissions) {
                            if ($p = $this.RoleManager.GetPermission($permissionName)) {
                                $this.LogDebug("Adding adhoc permission [$permissionName] to command [$($plugin.Name):$($cmd.name)]")
                                $cmd.AddPermission($p)
                            } else {
                                $this.LogInfo([LogSeverity]::Warning, "Adhoc permission [$permissionName] not found in Role Manager. Can't attach permission to command [$($plugin.Name):$($cmd.name)]")
                            }
                        }
                    }

                    $cmd.KeepHistory = $metadata.KeepHistory    # Default is $true
                    $cmd.HideFromHelp = $metadata.HideFromHelp  # Default is $false

                    # Set the trigger type to something other than 'Command'
                    if ($metadata.TriggerType) {
                        switch ($metadata.TriggerType) {
                            'Command' {
                                $cmd.TriggerType = [TriggerType]::Command
                                $cmd.Triggers += [Trigger]::new([TriggerType]::Command, $cmd.Name)

                                # Add any alternate command names as aliases to the command
                                if ($metadata.Aliases) {
                                    $metadata.Aliases | Foreach-Object {
                                        $cmd.Aliases += $_
                                        $triggers += [Trigger]::new([TriggerType]::Command, $_)
                                    }
                                }
                            }
                            'Event' {
                                $cmd.TriggerType = [TriggerType]::Event
                                $t = [Trigger]::new([TriggerType]::Event, $command.Name)

                                # The message type/subtype the command is intended to respond to
                                if ($metadata.MessageType) {
                                    $t.MessageType = $metadata.MessageType
                                }
                                if ($metadata.MessageSubtype) {
                                    $t.MessageSubtype = $metadata.MessageSubtype
                                }
                                $triggers += $t
                            }
                            'Regex' {
                                $cmd.TriggerType = [TriggerType]::Regex
                                $t = [Trigger]::new([TriggerType]::Regex, $command.Name)
                                $t.Trigger = $metadata.Regex
                                $triggers += $t
                            }
                        }
                    } else {
                        $triggers += [Trigger]::new([TriggerType]::Command, $cmd.Name)
                    }
                } else {
                    # No metadata defined so set the command name to the module function name
                    $cmd.Name = $command.Name
                    $triggers += [Trigger]::new([TriggerType]::Command, $cmd.Name)
                }

                # Get the command help so we can pull information from it
                # to construct the bot command
                $cmdHelp = Get-Help -Name $cmd.ModuleQualifiedCommand -ErrorAction SilentlyContinue
                if ($cmdHelp) {
                    $cmd.Description = $cmdHelp.Synopsis.Trim()
                }

                # Set the command usage differently for [Command] and [Regex] trigger types
                if ($cmd.TriggerType -eq [TriggerType]::Command) {
                    # Remove unneeded parameters from command syntax
                    if ($cmdHelp) {
                        $helpSyntax = ($cmdHelp.syntax | Out-String).Trim() -split "`n" | Where-Object {$_ -ne "`r"}
                        $helpSyntax = $helpSyntax -replace '\[\<CommonParameters\>\]', ''
                        $helpSyntax = $helpSyntax -replace '-Bot \<Object\> ', ''
                        $helpSyntax = $helpSyntax -replace '\[-Bot\] \<Object\> ', '['

                        # Replace the function name in the help syntax with
                        # what PoshBot will call the command
                        $helpSyntax = foreach ($item in $helpSyntax) {
                            $item -replace $command.Name, $cmd.Name
                        }
                        $cmd.Usage = $helpSyntax.ToLower().Trim()
                    } else {
                        $this.LogInfo([LogSeverity]::Warning, "Unable to parse help for command [$($command.Name)]")
                        $cmd.Usage = 'ERROR: Unable to parse command help'
                    }
                } elseIf ($cmd.TriggerType -eq [TriggerType]::Regex) {
                    $cmd.Usage = @($triggers | Select-Object -Expand Trigger) -join "`n"
                }

                # Add triggers based on command type and metadata
                $cmd.Triggers += $triggers

                $plugin.AddCommand($cmd)
            }

            # If the plugin was previously disabled in our plugin configuration, make sure it still is
            if ($pluginConfig -and (-not $pluginConfig.Enabled)) {
                $plugin.Deactivate()
            }

            $this.LoadCommands()

            if ($SaveAfterCreation) {
                $this.SaveState()
            }
        } else {
            $msg = "Unable to load module manifest [$ManifestPath]"
            $this.LogInfo([LogSeverity]::Error, $msg)
            Write-Error -Message $msg
        }
    }

    # Get the [Poshbot.BotComamnd()] attribute from the function if it exists
    [PoshBot.BotCommand]GetCommandMetadata([System.Management.Automation.FunctionInfo]$Command) {
        $attrs = $Command.ScriptBlock.Attributes
        $botCmdAttr = $attrs | ForEach-Object {
            if ($_.GetType().ToString() -eq 'PoshBot.BotCommand') {
                $_
            }
        }

        if ($botCmdAttr) {
            $this.LogDebug("Command [$($Command.Name)] has metadata defined")
        } else {
            $this.LogDebug("No metadata defined for command [$($Command.Name)]")
        }

        return $botCmdAttr
    }

    # Inspect the module manifest and return any permissions defined
    [Permission[]]GetPermissionsFromModuleManifest($Manifest) {
        $permissions = New-Object System.Collections.ArrayList
        foreach ($permission in $Manifest.PrivateData.Permissions) {
            if ($permission -is [string]) {
                $p = [Permission]::new($Permission)
                $permissions.Add($p)
            } elseIf ($permission -is [hashtable]) {
                $p = [Permission]::new($permission.Name)
                if ($permission.Description) {
                    $p.Description = $permission.Description
                }
                $permissions.Add($p)
            }
        }

        if ($permissions.Count -gt 0) {
            $this.LogDebug("Permissions defined in module manifest", $permissions)
        } else {
            $this.LogDebug('No permissions defined in module manifest')
        }

        return $permissions
    }

    # Load in the built in plugins
    # These will be marked so that they DON't execute in a PowerShell job
    # as they need access to the bot internals
    [void]LoadBuiltinPlugins() {
        $this.LogInfo('Loading builtin plugins')
        $builtinPlugin = Get-Item -Path "$($this._PoshBotModuleDir)/Plugins/Builtin"
        $moduleName = $builtinPlugin.BaseName
        $manifestPath = Join-Path -Path $builtinPlugin.FullName -ChildPath "$moduleName.psd1"
        $this.CreatePluginFromModuleManifest($moduleName, $manifestPath, $false, $false)
    }

    [hashtable]GetPluginConfig([string]$PluginName, [string]$Version) {
        $config = @{}
        if ($pluginConfig = $this._Storage.GetConfig('plugins')) {
            if ($thisPluginConfig = $pluginConfig[$PluginName]) {
                if (-not [string]::IsNullOrEmpty($Version)) {
                    if ($thisPluginConfig.ContainsKey($Version)) {
                        $pluginVersion = $Version
                    } else {
                        $this.LogDebug([LogSeverity]::Warning, "Plugin [$PluginName`:$Version] not defined in plugins.psd1")
                        return $null
                    }
                } else {
                    $pluginVersion = @($thisPluginConfig.Keys | Sort-Object -Descending)[0]
                }

                $pv = $thisPluginConfig[$pluginVersion]
                return $pv
            } else {
                $this.LogDebug([LogSeverity]::Warning, "Plugin [$PluginName] not defined in plugins.psd1")
                return $null
            }
        } else {
            $this.LogDebug([LogSeverity]::Warning, "No plugin configuration defined in storage")
            return $null
        }
    }
}
