
class PluginManager {

    [hashtable]$Plugins = @{}
    [hashtable]$Commands = @{}
    hidden [string]$_PoshBotModuleDir
    [Logger]$Logger

    PluginManager([Logger]$Logger, [string]$PoshBotModuleDir) {
        $this.Logger = $Logger
        $this._PoshBotModuleDir = $PoshBotModuleDir
        $this.Initialize()
    }

    # Initialize the plugin manager
    [void]Initialize() {
        $this.LoadBuiltinPlugins()
    }

    # Add a plugin to the bot
    [void]AddPlugin([Plugin]$Plugin) {
        if (-not $this.Plugins.ContainsKey($Plugin.Name)) {
            $this.Logger.Log([LogMessage]::new("[PluginManager:AddPlugin] Attaching plugin [$($Plugin.Name)]"), [LogType]::System)
            $this.Plugins.Add($Plugin.Name, $Plugin)
        }

        # # Reload commands and role from all currently loading (and active) plugins
        $this.LoadCommands()
        # $this.LoadRoles()
    }

    # Remove a plugin from the bot
    [void]RemovePlugin([Plugin]$Plugin) {
        if ($this.Plugins.ContainsKey($Plugin.Name)) {
            $this.Logger.Log([LogMessage]::new("[PluginManager:RemovePlugin] Removing plugin [$Plugin.Name]"), [LogType]::System)
            $this.Plugins.Remove($Plugin.Name)
        }

        # Reload commands from all currently loading (and active) plugins
        $this.LoadCommands()
    }

    # Activate a plugin
    [void]ActivatePlugin([Plugin]$Plugin) {
        $p = $this.Plugins[$Plugin.Name]
        if ($p) {
            $this.Logger.Log([LogMessage]::new("[PluginManager:ActivatePlugin] Activating plugin [$Plugin.Name]"), [LogType]::System)
            $p.Activate()
        } else {
            throw [PluginNotFoundException]::New("Plugin [$($Plugin.Name)] is not loaded in bot")
        }

        # Reload commands from all currently loading (and active) plugins
        $this.LoadCommands()
    }

    # Deactivate a plugin
    [void]DeactivatePlugin([Plugin]$Plugin) {
        $p = $this.Plugins[$Plugin.Name]
        if ($p) {
            $this.Logger.Log([LogMessage]::new("[PluginManager:DeactivatePlugin] Deactivating plugin [$Plugin.Name]"), [LogType]::System)
            $p.Deactivate()
        } else {
            throw [PluginNotFoundException]::New("Plugin [$($Plugin.Name)] is not loaded in bot")
        }

        # # Reload commands from all currently loading (and active) plugins
        $this.LoadCommands()
    }

     # Match a parsed command to a command in one of the currently loaded plugins
    [PluginCommand]MatchCommand([ParsedCommand]$ParsedCommand) {

        # Check builtin commands first
        $builtinPlugin = $this.Plugins['Builtin']
        foreach ($commandKey in $builtinPlugin.Commands.Keys) {
            $command = $builtinPlugin.Commands[$commandKey]
            if ($command.TriggerMatch($ParsedCommand)) {
                $this.Logger.Log([LogMessage]::new("[PluginManagerBot:MatchCommand] Matched parsed command [$($ParsedCommand.Plugin)`:$($ParsedCommand.Command)] to builtin command [Builtin:$commandKey]"), [LogType]::System)
                return [PluginCommand]::new($builtinPlugin, $command)
                #return $command
            }
        }

        # If parsed command is fully qualified with <plugin:command> syntax. Just look in that plugin
        if (($ParsedCommand.Plugin -ne [string]::Empty) -and ($ParsedCommand.Command -ne [string]::Empty)) {
            $plugin = $this.Plugins[$ParsedCommand.Plugin]
            if ($plugin) {
                foreach ($commandKey in $plugin.Commands.Keys) {
                    $command = $plugin.Commands[$commandKey]
                    if ($command.TriggerMatch($ParsedCommand)) {
                        $this.Logger.Log([LogMessage]::new("[PluginManager:MatchCommand] Matched parsed command [$($ParsedCommand.Plugin)`:$($ParsedCommand.Command)] to plugin command [$($plugin.Name)`:$commandKey]"), [LogType]::System)
                        return [PluginCommand]::new($plugin, $command)
                        #return $command
                    }
                }
                $this.Logger.Log([LogMessage]::new("[PluginManager:MatchCommand] Unable to match parsed command [$($ParsedCommand.Plugin)`:$($ParsedCommand.Command)] to a command in plugin [$($plugin.Name)]"), [LogType]::System)
            } else {
                $this.Logger.Log([LogMessage]::new("[PluginManager:MatchCommand] Unable to match parsed command [$($ParsedCommand.Plugin)`:$($ParsedCommand.Command)] to a plugin command"), [LogType]::System)
                return $null
            }
        } else {
            # Check all regular plugins/commands now
            foreach ($pluginKey in $this.Plugins.Keys) {
                $plugin = $this.Plugins[$pluginKey]
                foreach ($commandKey in $plugin.Commands.Keys) {
                    $command = $plugin.Commands[$commandKey]
                    if ($command.TriggerMatch($ParsedCommand)) {
                        $this.Logger.Log([LogMessage]::new("[PluginManager:MatchCommand] Matched parsed command [$($ParsedCommand.Plugin)`:$($ParsedCommand.Command)] to plugin command [$pluginKey`:$commandKey]"), [LogType]::System)
                        return [PluginCommand]::new($plugin, $command)
                        return $command
                    }
                }
            }
        }

        $this.Logger.Log([LogMessage]::new("[PluginManager:MatchCommand] Unable to match parsed command [$($ParsedCommand.Plugin)`:$($ParsedCommand.Command)] to a plugin command"), [LogType]::System)
        return $null
    }

    # Load in the available commands from all the loaded plugins
    [void]LoadCommands() {
        $allCommands = New-Object System.Collections.ArrayList
        foreach ($pluginKey in $this.Plugins.Keys) {
            $plugin = $this.Plugins[$pluginKey]
            if ($plugin.Enabled) {
                foreach ($commandKey in $plugin.Commands.Keys) {
                    $command =  $plugin.Commands[$commandKey]
                    $fullyQualifiedCommandName = "$pluginKey`:$CommandKey"
                    $allCommands.Add($fullyQualifiedCommandName)
                    if (-not $this.Commands.ContainsKey($fullyQualifiedCommandName)) {
                        $this.Logger.Log([LogMessage]::new("[PluginManager:LoadCommands] Loading command [$fullyQualifiedCommandName]"), [LogType]::System)
                        $this.Commands.Add($fullyQualifiedCommandName, $command)
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
            $this.Logger.Log([LogMessage]::new("[PluginManager:LoadCommands] Removing command [$_]. Plugin has either been removed or is deactivated."), [LogType]::System)
            $this.Commands.Remove($_)
            #$this.Triggers.Remove($_)
        }
    }

    # Load in the built in plugins
    # Thee will be marked so that they DON't execute in a PowerShell job
    # as they need access to the bot internals
    [void]LoadBuiltinPlugins() {
        $pluginsToLoad = Get-ChildItem -Path "$($this._PoshBotModuleDir)/Plugins" -Directory
        foreach ($dir in $pluginsToLoad) {
            $moduleName = $dir.Name
            $manifestPath = Join-Path -Path $dir.FullName -ChildPath "$moduleName.psd1"
            $modManifest = Test-ModuleManifest -Path $manifestPath -ErrorAction SilentlyContinue
            $manifest = Import-PowerShellDataFile -Path $manifestPath -ErrorAction SilentlyContinue

            # Create a new plugin and command(s) using information from this module
            if ($modManifest -and $manifest) {
                $plugin = [Plugin]::new()
                $plugin.Name = $moduleName
                foreach ($role in $manifest.PrivateData.Roles) {
                    $pluginRole = [Role]::new($role)
                    $plugin.AddRole($pluginRole)
                }

                Import-Module -Name $manifestPath -Scope Local
                $moduleCommands = Get-Command -Module $moduleName -CommandType Cmdlet, Function, Workflow
                foreach ($command in $moduleCommands) {

                    # Get the command help so we can pull information from it
                    # to construct the bot command
                    $cmdHelp = Get-Help -Name $command.Name

                    $cmd = [Command]::new()
                    $cmd.Name = $command.Name
                    $cmd.Description = $cmdHelp.Synopsis
                    $cmd.ManifestPath = $manifestPath
                    $cmd.FunctionInfo = $command
                    $cmd.Trigger = [Trigger]::new('Command', $command.Name)
                    $cmd.HelpText = $cmdHelp.examples[0].example[0].code
                    $cmd.ModuleCommand = "$moduleName\$($command.Name)"
                    $cmd.AsJob = $false
                    #$cmd.AddRole([Role]::new($cmdHelp.Role))

                    $this.Logger.Log([LogMessage]::new("[PluginManager:LoadBuiltinPlugins] Loading command [$($command.Name)] into plugin [$plugin.Name]"), [LogType]::System)
                    $plugin.AddCommand($cmd)
                }

                $this.Logger.Log([LogMessage]::new("[PluginManager:LoadBuiltinPlugins] Loading plugin [$($plugin.Name)]"), [LogType]::System)
                $this.AddPlugin($plugin)
            }
        }
    }
}
