
class PluginManager {

    [hashtable]$Plugins = @{}
    [hashtable]$Commands = @{}
    hidden [string]$_PoshBotModuleDir
    [RoleManager]$RoleManager
    [StorageProvider]$_Storage
    [Logger]$Logger

    PluginManager([RoleManager]$RoleManager, [StorageProvider]$Storage, [Logger]$Logger, [string]$PoshBotModuleDir) {
        $this.RoleManager = $RoleManager
        $this._Storage = $Storage
        $this.Logger = $Logger
        $this._PoshBotModuleDir = $PoshBotModuleDir
        $this.Initialize()
    }

    # Initialize the plugin manager
    [void]Initialize() {
        $this.Logger.Info([LogMessage]::new('[PluginManager:Initialize] Initializing'))
        $this.LoadState()
        $this.LoadBuiltinPlugins()
    }

    # Get the list of plugins to load and... wait for it... load them
    [void]LoadState() {
        $this.Logger.Verbose([LogMessage]::new('[PluginManager:LoadState] Loading plugin state from storage'))

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
        $this.Logger.Verbose([LogMessage]::new('[PluginManager:SaveState] Saving loaded plugin state to storage'))

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
            Write-Error -Message "Module manifest path [$manifestPath] not found"
        }
    }

    # Add a plugin to the bot
    [void]AddPlugin([Plugin]$Plugin, [bool]$SaveAfterInstall = $false) {
        if (-not $this.Plugins.ContainsKey($Plugin.Name)) {
            $this.Logger.Info([LogMessage]::new("[PluginManager:AddPlugin] Attaching plugin [$($Plugin.Name)]"))

            $pluginVersion = @{
                ($Plugin.Version).ToString() = $Plugin
            }
            $this.Plugins.Add($Plugin.Name, $pluginVersion)

            # Register the plugins permission set with the role manager
            foreach ($permission in $Plugin.Permissions.GetEnumerator()) {
                $this.Logger.Info([LogMessage]::new("[PluginManager:AddPlugin] Adding permission [$($permission.Value.ToString())] to Role Manager"))
                $this.RoleManager.AddPermission($permission.Value)
            }
        } else {

            if (-not $this.Plugins[$Plugin.Name].ContainsKey($Plugin.Version)) {
                # Install a new plugin version
                $this.Logger.Info([LogMessage]::new("[PluginManager:AddPlugin] Attaching version [$($Plugin.Version)] of plugin [$($Plugin.Name)]"))

                $this.Plugins[$Plugin.Name].Add($Plugin.Version.ToString(), $Plugin)

                # Register the plugins permission set with the role manager
                foreach ($permission in $Plugin.Permissions.GetEnumerator()) {
                    $this.Logger.Info([LogMessage]::new("[PluginManager:AddPlugin] Adding permission [$($permission.Value.ToString())] to Role Manager"))
                    $this.RoleManager.AddPermission($permission.Value)
                }
            } else {
                throw [PluginException]::New("Plugin [$($Plugin.Name)] version [$($Plugin.Version)] is already loaded")
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
                    $this.Logger.Verbose([LogMessage]::new("[PluginManager:RemovePlugin] Removing permission [$($Permission.Value.ToString())]. No longer in use"))
                    $this.RoleManager.RemovePermission($Permission.Value)
                }
                $this.Logger.Info([LogMessage]::new("[PluginManager:RemovePlugin] Removing plugin [$($Plugin.Name)]"))
                $this.Plugins.Remove($Plugin.Name)
            } else {
                if ($pluginVersions.ContainsKey($Plugin.Version)) {
                    $this.Logger.Info([LogMessage]::new("[PluginManager:RemovePlugin] Removing plugin [$($Plugin.Name)] version [$($Plugin.Version)]"))
                    $pluginVersions.Remove($Plugin.Version)
                } else {
                    throw [PluginNotFoundException]::New("Plugin [$($Plugin.Name)] version [$($Plugin.Version)] is not loaded in bot")
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
                        $this.Logger.Verbose([LogMessage]::new("[PluginManager:RemovePlugin] Removing permission [$($Permission.Value.ToString())]. No longer in use"))
                        $this.RoleManager.RemovePermission($Permission.Value)
                    }
                    $this.Logger.Info([LogMessage]::new("[PluginManager:RemovePlugin] Removing plugin [$($pv.Name)]"))
                    $this.Plugins.Remove($pv.Name)
                } else {
                    $this.Logger.Info([LogMessage]::new("[PluginManager:RemovePlugin] Removing plugin [$($pv.Name)] version [$Version]"))
                    $p.Remove($pv.Version.ToString())
                }
            } else {
                throw [PluginNotFoundException]::New("Plugin [$PluginName] version [$Version] is not loaded in bot")
            }
        } else {
            throw [PluginNotFoundException]::New("Plugin [$PluginName] is not loaded in bot")
        }

        # Reload commands from all currently loading (and active) plugins
        $this.LoadCommands()

        $this.SaveState()
    }

    # Activate a plugin
    [void]ActivatePlugin([string]$PluginName, [string]$Version) {
        if ($p = $this.Plugins[$PluginName]) {
            if ($pv = $p[$Version]) {
                $this.Logger.Info([LogMessage]::new("[PluginManager:ActivatePlugin] Activating plugin [$PluginName] version [$Version]"))
                $pv.Activate()

                # Reload commands from all currently loading (and active) plugins
                $this.LoadCommands()
                $this.SaveState()
            } else {
                throw [PluginNotFoundException]::New("Plugin [$PluginName] version [$Version] is not loaded in bot")
            }
        } else {
            throw [PluginNotFoundException]::New("Plugin [$PluginName] is not loaded in bot")
        }
    }

    # Activate a plugin
    [void]ActivatePlugin([Plugin]$Plugin) {
        $p = $this.Plugins[$Plugin.Name]
        if ($p) {
            if ($pv = $p[$Plugin.Version.ToString()]) {
                $this.Logger.Info([LogMessage]::new("[PluginManager:ActivatePlugin] Activating plugin [$($Plugin.Name)] version [$($Plugin.Version)]"))
                $pv.Activate()
            }
        } else {
            throw [PluginNotFoundException]::New("Plugin [$($Plugin.Name)] version [$($Plugin.Version)] is not loaded in bot")
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
                $this.Logger.Info([LogMessage]::new("[PluginManager:DeactivatePlugin] Deactivating plugin [$($Plugin.Name)] version [$($Plugin.Version)]"))
                $pv.Deactivate()
            }
        } else {
            throw [PluginNotFoundException]::New("Plugin [$($Plugin.Name)] version [$($Plugin.Version)] is not loaded in bot")
        }

        # # Reload commands from all currently loading (and active) plugins
        $this.LoadCommands()

        $this.SaveState()
    }

    # Deactivate a plugin
    [void]DeactivatePlugin([string]$PluginName, [string]$Version) {
        if ($p = $this.Plugins[$PluginName]) {
            if ($pv = $p[$Version]) {
                $this.Logger.Info([LogMessage]::new("[PluginManager:DeactivatePlugin] Deactivating plugin [$PluginName)] version [$Version]"))
                $pv.Deactivate()

                # Reload commands from all currently loading (and active) plugins
                $this.LoadCommands()
                $this.SaveState()
            } else {
                throw [PluginNotFoundException]::New("Plugin [$PluginName] version [$Version] is not loaded in bot")
            }
        } else {
            throw [PluginNotFoundException]::New("Plugin [$PluginName] is not loaded in bot")
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
                $this.Logger.Info([LogMessage]::new("[PluginManagerBot:MatchCommand] Matched parsed command [$($ParsedCommand.Plugin)`:$($ParsedCommand.Command)] to builtin command [Builtin:$commandKey]"))
                return [PluginCommand]::new($builtinPlugin, $command)
            }
        }

        # If parsed command is fully qualified with <plugin:command> syntax. Just look in that plugin
        if (($ParsedCommand.Plugin -ne [string]::Empty) -and ($ParsedCommand.Command -ne [string]::Empty)) {
            $plugin = $this.Plugins[$ParsedCommand.Plugin]
            if ($plugin) {

                # Just look in the latest version of the plugin.
                # This should be improved later to allow specifying a specific version to execute
                $latestVersionKey = $plugin.Keys | Sort-Object -Descending | Select-Object -First 1
                $pluginVersion = $plugin[$latestVersionKey]

                foreach ($commandKey in $pluginVersion.Commands.Keys) {
                    $command = $pluginVersion.Commands[$commandKey]
                    if ($command.TriggerMatch($ParsedCommand, $CommandSearch)) {
                        $this.Logger.Info([LogMessage]::new("[PluginManager:MatchCommand] Matched parsed command [$($ParsedCommand.Plugin)`:$($ParsedCommand.Command)] to plugin command [$($plugin.Name)`:$commandKey]"))
                        return [PluginCommand]::new($pluginVersion, $command)
                    }
                }
                $this.Logger.Info([LogMessage]::new([LogSeverity]::Warning, "[PluginManager:MatchCommand] Unable to match parsed command [$($ParsedCommand.Plugin)`:$($ParsedCommand.Command)] to a command in plugin [$($plugin.Name)]"))
            } else {
                $this.Logger.Info([LogMessage]::new([LogSeverity]::Warning, "[PluginManager:MatchCommand] Unable to match parsed command [$($ParsedCommand.Plugin)`:$($ParsedCommand.Command)] to a plugin command"))
                return $null
            }
        } else {

            # Check all regular plugins/commands now
            foreach ($pluginKey in $this.Plugins.Keys) {
                $plugin = $this.Plugins[$pluginKey]

                # Just look in the latest version of the plugin.
                # This should be improved later to allow specifying a specific version to execute
                foreach ($pluginVersionKey in $plugin.Keys | Sort-Object -Descending | Select-Object -First 1) {
                    $pluginVersion = $plugin[$pluginVersionKey]

                    foreach ($commandKey in $pluginVersion.Commands.Keys) {
                        $command = $pluginVersion.Commands[$commandKey]
                        if ($command.TriggerMatch($ParsedCommand, $CommandSearch)) {
                            $this.Logger.Info([LogMessage]::new("[PluginManager:MatchCommand] Matched parsed command [$($ParsedCommand.Plugin)`:$($ParsedCommand.Command)] to plugin command [$pluginKey`:$commandKey]"))
                            return [PluginCommand]::new($pluginVersion, $command)
                        }
                    }
                }
            }
        }

        $this.Logger.Info([LogMessage]::new([LogSeverity]::Warning, "[PluginManager:MatchCommand] Unable to match parsed command [$($ParsedCommand.Plugin)`:$($ParsedCommand.Command)] to a plugin command"))
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
                        $fullyQualifiedCommandName = "$pluginKey`:$CommandKey"
                        $allCommands.Add($fullyQualifiedCommandName)
                        if (-not $this.Commands.ContainsKey($fullyQualifiedCommandName)) {
                            $this.Logger.Verbose([LogMessage]::new("[PluginManager:LoadCommands] Loading command [$fullyQualifiedCommandName]"))
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
            $this.Logger.Verbose([LogMessage]::new("[PluginManager:LoadCommands] Removing command [$_]. Plugin has either been removed or is deactivated."))
            $this.Commands.Remove($_)
        }
    }

    # Create a new plugin from a given module manifest
    [void]CreatePluginFromModuleManifest([string]$ModuleName, [string]$ManifestPath, [bool]$AsJob = $true, [bool]$SaveAfterCreation = $false) {
        $manifest = Import-PowerShellDataFile -Path $ManifestPath -ErrorAction SilentlyContinue
        if ($manifest) {
            $plugin = [Plugin]::new()
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
                        $this.Logger.Debug([LogMessage]::new("[PluginManager:CreatePluginFromModuleManifest] Adding adhoc permission [$permissionName] to plugin [$($plugin.Name)]"))
                        $plugin.AddPermission($p)
                    } else {
                        $this.Logger.Info([LogMessage]::new("[PluginManager:CreatePluginFromModuleManifest] Adhoc permission [$permissionName] not found in Role Manager. Can't attach permission to plugin [$($plugin.Name)]"))
                    }
                }
            }

            # Add the plugin so the roles can be registered with the role manager
            $this.AddPlugin($plugin, $SaveAfterCreation)
            $this.Logger.Info([LogMessage]::new("[PluginManager:CreatePluginFromModuleManifest] Created new plugin [$($plugin.Name)]"))

            # Get exported cmdlets/functions from the module and add them to the plugin
            # Adjust bot command behaviour based on metadata as appropriate
            Import-Module -Name $manifestPath -Scope Local -Verbose:$false -WarningAction SilentlyContinue
            $moduleCommands = Microsoft.PowerShell.Core\Get-Command -Module $ModuleName -CommandType @('Cmdlet', 'Function', 'Workflow') -Verbose:$false
            foreach ($command in $moduleCommands) {

                # Get the command help so we can pull information from it
                # to construct the bot command
                $cmdHelp = Get-Help -Name $command.Name

                # Get any command metadata that may be attached to the command
                # via the PoshBot.BotCommand extended attribute
                $metadata = $this.GetCommandMetadata($command)

                $this.Logger.Info([LogMessage]::new("[PluginManager:CreatePluginFromModuleManifest] Creating command [$($command.Name)] for new plugin [$($plugin.Name)]"))
                $cmd = [Command]::new()

                # Set command properties based on metadata from module
                if ($metadata) {
                    # Set the command name / trigger to the module function name or to
                    # what is defined in the metadata
                    if ($metadata.CommandName) {
                        $cmd.Trigger = [Trigger]::new('Command', $metadata.CommandName)
                        $cmd.Name = $metadata.CommandName
                    } else {
                        $cmd.Trigger = [Trigger]::new('Command', $command.Name)
                        $cmd.name = $command.Name
                    }

                    # Add any permissions definede within the plugin to the command
                    if ($metadata.Permissions) {
                        foreach ($item in $metadata.Permissions) {
                            $fqPermission = "$($plugin.Name):$($item)"
                            if ($p = $plugin.GetPermission($fqPermission)) {
                                $cmd.AddPermission($p)
                            } else {
                                Write-Error -Message "Permission [$fqPermission] is not defined in the plugin module manifest. Command will not be added to plugin."
                                continue
                            }
                        }
                    }

                    # Add any adhoc permissions that we may have been added in the past
                    # that is stored in our plugin configuration
                    if ($pluginConfig) {
                        foreach ($permissionName in $pluginConfig.AdhocPermissions) {
                            if ($p = $this.RoleManager.GetPermission($permissionName)) {
                                $this.Logger.Debug([LogMessage]::new("[PluginManager:CreatePluginFromModuleManifest] Adding adhoc permission [$permissionName] to command [$($plugin.Name):$($cmd.name)]"))
                                $cmd.AddPermission($p)
                            } else {
                                $this.Logger.Info([LogMessage]::new("[PluginManager:CreatePluginFromModuleManifest] Adhoc permission [$permissionName] not found in Role Manager. Can't attach permission to command [$($plugin.Name):$($cmd.name)]"))
                            }
                        }
                    }

                    $cmd.KeepHistory = $metadata.KeepHistory    # Default is $true
                    $cmd.HideFromHelp = $metadata.HideFromHelp  # Default is $false

                    # Set the trigger type
                    if ($metadata.TriggerType) {
                        switch ($metadata.TriggerType) {
                            'Comamnd' {
                                $cmd.Trigger.Type = [TriggerType]::Command
                            }
                            'Event' {
                                $cmd.Trigger.Type = [TriggerType]::Event
                            }
                            'Regex' {
                                $cmd.Trigger.Type = [TriggerType]::Regex
                                $cmd.Trigger.Trigger = $metadata.Regex
                            }
                        }
                    } else {
                        $cmd.Trigger.Type = [TriggerType]::Command
                    }

                    # The message type/subtype the command is intended to respond to
                    if ($metadata.MessageType) {
                        $cmd.Trigger.MessageType = $metadata.MessageType
                    }
                    if ($metadata.MessageSubtype) {
                        $cmd.Trigger.MessageSubtype = $metadata.MessageSubtype
                    }
                } else {
                    # No metadata defined so set the command name/trigger to the module function name
                    $cmd.Name = $command.Name
                    $cmd.Trigger = [Trigger]::new('Command', $command.Name)
                }

                $cmd.Description = $cmdHelp.Synopsis.Trim()
                $cmd.ManifestPath = $manifestPath
                $cmd.FunctionInfo = $command

                if ($cmdHelp.examples) {
                    foreach ($example in $cmdHelp.Examples.Example) {
                        $cmd.Usage += $example.code.Trim()
                    }
                }
                $cmd.ModuleCommand = "$ModuleName\$($command.Name)"
                $cmd.AsJob = $AsJob

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
        }
    }

    # Get the [Poshbot.BotComamnd()] attribute from the function if it exists
    [PoshBot.BotCommand]GetCommandMetadata([System.Management.Automation.FunctionInfo]$Command) {
        $attrs = $Command.ScriptBlock.Attributes
        $botCmdAttr = $attrs | ForEach-Object {
            if ($_.TypeId.ToString() -eq 'PoshBot.BotCommand') {
                $_
            }
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
        return $permissions
    }

    # Load in the built in plugins
    # These will be marked so that they DON't execute in a PowerShell job
    # as they need access to the bot internals
    [void]LoadBuiltinPlugins() {
        $this.Logger.Info([LogMessage]::new('[PluginManager:LoadBuiltinPlugins] Loading builtin plugins'))
        $builtinPlugin = Get-Item -Path "$($this._PoshBotModuleDir)/Plugins/Builtin"
        $moduleName = $builtinPlugin.BaseName
        $manifestPath = Join-Path -Path $builtinPlugin.FullName -ChildPath "$moduleName.psd1"
        $this.CreatePluginFromModuleManifest($moduleName, $manifestPath, $false, $false)
    }

    [hashtable]GetPluginConfig([string]$PluginName, [string]$Version) {
        if ($pluginConfig = $this._Storage.GetConfig('plugins')) {
            if ($thisPluginConfig = $pluginConfig[$PluginName]) {
                if (-not [string]::IsNullOrEmpty($Version)) {
                    if ($thisPluginConfig.ContainsKey($Version)) {
                        $pluginVersion = $Version
                    } else {
                        return $null
                    }
                } else {
                    $pluginVersion = @($thisPluginConfig.Keys | Sort-Object -Descending)[0]
                }

                $pv = $thisPluginConfig[$pluginVersion]
                return $pv
            } else {
                return $null
            }
        } else {
            return $null
        }
    }
}
