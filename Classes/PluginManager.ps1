
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

    [void]LoadState() {
        $this.Logger.Verbose([LogMessage]::new('[PluginManager:SaveState] Loading plugin state from storage'))

        $pluginsToLoad = $this._Storage.GetConfig('plugins')
        if ($pluginsToLoad) {
            $pluginsToLoad.GetEnumerator() | ForEach-Object {
                $pluginName = $_.Value.Name
                $manifestPath = $_.Value.ManifestPath
                $this.CreatePluginFromModuleManifest($pluginName, $manifestPath, $true)
            }
        }
    }

    [void]SaveState() {
        $this.Logger.Verbose([LogMessage]::new('[PluginManager:SaveState] Saving loaded plugin state to storage'))

        # Skip saving builtin plugin as it will always be loaded at initialization
        $pluginsToSave = @{}
        $this.Plugins.GetEnumerator() | Where {$_.Value.Name -ne 'Builtin'} | ForEach-Object {
            $p = @{
                Name = $_.Name
                ManifestPath = $_.Value._ManifestPath
                Enabled = $_.Value.Enabled
            }
            $pluginsToSave.Add($_.Name, $p)
            $this._Storage.SaveConfig('plugins', $pluginsToSave)
        }
    }

    # TODO
    # Given a PowerShell module definition, inspect it for commands etc,
    # create a plugin instance and load the plugin
    [void]InstallPlugin([string]$ManifestPath) {
        if (Test-Path -Path $ManifestPath) {
            $moduleName = (Get-Item -Path $ManifestPath).BaseName
            $this.CreatePluginFromModuleManifest($moduleName, $ManifestPath, $true)
        } else {
            Write-Error -Message "Module manifest path [$manifestPath] not found"
        }
    }

    # Add a plugin to the bot
    [void]AddPlugin([Plugin]$Plugin) {
        if (-not $this.Plugins.ContainsKey($Plugin.Name)) {
            $this.Logger.Info([LogMessage]::new("[PluginManager:AddPlugin] Attaching plugin [$($Plugin.Name)]"))
            $this.Plugins.Add($Plugin.Name, $Plugin)

            # Register the plugin's roles with the role manager
            foreach ($role in $Plugin.Roles.GetEnumerator()) {
                $this.Logger.Info([LogMessage]::new("[PluginManager:AddPlugin] Adding role [$($Role.Name)] to Role Manager"))
                $this.RoleManager.AddRole($role.Value)
            }
        }

        # # Reload commands and role from all currently loading (and active) plugins
        $this.LoadCommands()

        $this.SaveState()
    }

    # Remove a plugin from the bot
    [void]RemovePlugin([Plugin]$Plugin) {
        if ($this.Plugins.ContainsKey($Plugin.Name)) {

            # Remove the roles for this plugin from the role manager
            # if those roles are not associtate with any other plugins
            foreach ($role in $Plugin.Roles) {
                $roleIsUnique = $true
                $otherPluginKeys = $this.Plugins.Keys | Where {$_ -ne $Plugin.Name}
                foreach ($otherPluginKey in $otherPluginKeys) {
                    if ($this.Plugins[$otherPluginKey].Roles -contains $role.Name) {
                        $roleIsUnique = $false
                    }
                }
                if ($roleIsUnique) {
                    $this.Logger.Verbose([LogMessage]::new("[PluginManager:RemovePlugin] Removing role [$Role.Name]. No longer in use"))
                    $this.RoleManager.RemoveRole($role)
                }
            }

            $this.Logger.Info([LogMessage]::new("[PluginManager:RemovePlugin] Removing plugin [$Plugin.Name]"))
            $this.Plugins.Remove($Plugin.Name)
        }

        # Reload commands from all currently loading (and active) plugins
        $this.LoadCommands()

        $this.SaveState()
    }

    # Activate a plugin
    [void]ActivatePlugin([Plugin]$Plugin) {
        $p = $this.Plugins[$Plugin.Name]
        if ($p) {
            $this.Logger.Info([LogMessage]::new("[PluginManager:ActivatePlugin] Activating plugin [$Plugin.Name]"))
            $p.Activate()
        } else {
            throw [PluginNotFoundException]::New("Plugin [$($Plugin.Name)] is not loaded in bot")
        }

        # Reload commands from all currently loading (and active) plugins
        $this.LoadCommands()

        $this.SaveState()
    }

    # Deactivate a plugin
    [void]DeactivatePlugin([Plugin]$Plugin) {
        $p = $this.Plugins[$Plugin.Name]
        if ($p) {
            $this.Logger.Info([LogMessage]::new("[PluginManager:DeactivatePlugin] Deactivating plugin [$Plugin.Name]"))
            $p.Deactivate()
        } else {
            throw [PluginNotFoundException]::New("Plugin [$($Plugin.Name)] is not loaded in bot")
        }

        # # Reload commands from all currently loading (and active) plugins
        $this.LoadCommands()

        $this.SaveState()
    }

     # Match a parsed command to a command in one of the currently loaded plugins
    [PluginCommand]MatchCommand([ParsedCommand]$ParsedCommand) {

        # Check builtin commands first
        $builtinPlugin = $this.Plugins['Builtin']
        foreach ($commandKey in $builtinPlugin.Commands.Keys) {
            $command = $builtinPlugin.Commands[$commandKey]
            if ($command.TriggerMatch($ParsedCommand)) {
                $this.Logger.Info([LogMessage]::new("[PluginManagerBot:MatchCommand] Matched parsed command [$($ParsedCommand.Plugin)`:$($ParsedCommand.Command)] to builtin command [Builtin:$commandKey]"))
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
                        $this.Logger.Info([LogMessage]::new("[PluginManager:MatchCommand] Matched parsed command [$($ParsedCommand.Plugin)`:$($ParsedCommand.Command)] to plugin command [$($plugin.Name)`:$commandKey]"))
                        return [PluginCommand]::new($plugin, $command)
                        #return $command
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
                foreach ($commandKey in $plugin.Commands.Keys) {
                    $command = $plugin.Commands[$commandKey]
                    if ($command.TriggerMatch($ParsedCommand)) {

                        # # Check if this is a subcommand
                        # if ($command.SubCommands.Count -gt 0) {
                        #     $this.Logger.Log([LogMessage]::new("[PluginManager:MatchCommand] This command has subcommands"), [LogType]::System)

                        #     # Is subcommand given?
                        #     if ($ParsedCommand.PositionalParameters.Count -gt 0) {

                        #         # The subcommand name should be the second token of the command string
                        #         $subCommandName = $ParsedCommand.Tokens[1]

                        #         # Remove the subCommandName from the PositionalParameters collection so it doesn't get passed
                        #         # as an argument when invoking the command
                        #         $ParsedCommand.PositionalParameters = @($ParsedCommand.PositionalParameters | where {$_ -ne $subCommandName})

                        #         $this.Logger.Log([LogMessage]::new("[PluginManager:MatchCommand] Looking for subcommand [$subCommandName]"), [LogType]::System)

                        #         foreach ($subCommand in $command.Subcommands.GetEnumerator()) {
                        #             $this.Logger.Log([LogMessage]::new("[PluginManager:MatchCommand] looking for [$subCommandName]"), [LogType]::System)
                        #             if ($subCommand.Value.Name -eq $subCommandName) {
                        #                 $this.Logger.Log([LogMessage]::new("[PluginManager:MatchCommand] Found subcommand [$subCommandName]"), [LogType]::System)
                        #                 return [PluginCommand]::new($plugin, $subCommand.Value)
                        #             }
                        #         }
                        #     }

                        #     # The command has subcommands bet we are invoking the primary command
                        #     $this.Logger.Log([LogMessage]::new("[PluginManager:MatchCommand] Matched parsed command [$($ParsedCommand.Plugin)`:$($ParsedCommand.Command)] to plugin command [$pluginKey`:$commandKey]"), [LogType]::System)
                        #     return [PluginCommand]::new($plugin, $command)
                        # } else {
                            $this.Logger.Info([LogMessage]::new("[PluginManager:MatchCommand] Matched parsed command [$($ParsedCommand.Plugin)`:$($ParsedCommand.Command)] to plugin command [$pluginKey`:$commandKey]"))
                            return [PluginCommand]::new($plugin, $command)
                        #}
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
            if ($plugin.Enabled) {
                foreach ($commandKey in $plugin.Commands.Keys) {
                    $command =  $plugin.Commands[$commandKey]
                    $fullyQualifiedCommandName = "$pluginKey`:$CommandKey"
                    $allCommands.Add($fullyQualifiedCommandName)
                    if (-not $this.Commands.ContainsKey($fullyQualifiedCommandName)) {
                        $this.Logger.Verbose([LogMessage]::new("[PluginManager:LoadCommands] Loading command [$fullyQualifiedCommandName]"))
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
            $this.Logger.Verbose([LogMessage]::new("[PluginManager:LoadCommands] Removing command [$_]. Plugin has either been removed or is deactivated."))
            $this.Commands.Remove($_)
            #$this.Triggers.Remove($_)
        }
    }

    [void]CreatePluginFromModuleManifest([string]$ModuleName, [string]$ManifestPath, [bool]$AsJob = $true) {
        $manifest = Import-PowerShellDataFile -Path $ManifestPath -ErrorAction SilentlyContinue
        if ($manifest) {
            $plugin = [Plugin]::new()
            $plugin.Name = $ModuleName
            $plugin._ManifestPath = $ManifestPath

            # Create new roles from metadata in the module manifest
            $pluginRoles = $this.GetRoleFromModuleManifest($manifest)
            $pluginRoles | ForEach-Object {
                $plugin.AddRole($_)
            }

            # Add the plugin so the roles can be registered with the role manager
            $this.AddPlugin($plugin)
            $this.Logger.Info([LogMessage]::new("[PluginManager:CreatePluginFromModuleManifest] Created new plugin [$($plugin.Name)]"))

            Import-Module -Name $manifestPath -Scope Local -Verbose:$false
            $moduleCommands = Get-Command -Module $ModuleName -CommandType Cmdlet, Function, Workflow
            foreach ($command in $moduleCommands) {

                # # See if this command should be a subcommand
                # $isSubcommand = $this.IsSubcommand($Command.Name)
                # $primaryCommandName = $null
                # #$subCommandName = $null
                # $subCommandTrigger = $null
                # if ($isSubcommand) {
                #     $primaryCommandName = $Command.Name.Split('-')[0].Split('_')[0]
                #     $subCommandTrigger = $Command.Name.Replace('-', ' ').Replace('_', ' ')
                #     $this.Logger.Log([LogMessage]::new("[PluginManager:CreatePluginFromModuleManifest] Command [$($command.Name)] is a subcommand of [$primaryCommandName] "), [LogType]::System)
                # }

                # Get the command help so we can pull information from it
                # to construct the bot command
                $cmdHelp = Get-Help -Name $command.Name

                $metadata = $this.GetCommandMetadata($command)

                $this.Logger.Info([LogMessage]::new("[PluginManager:CreatePluginFromModuleManifest] Creating command [$($command.Name)] for new plugin [$($plugin.Name)]"))
                $cmd = [Command]::new()

                # Normally, bot commands only respond to normal messages received from the chat network
                # To respond to other message types/subtypes, metadata must be added to the function to
                # call out the exact message type/subtype the command is designed to respond to
                $trigger = [Trigger]::new('Command', $command.Name)
                $cmd.Trigger = $trigger

                # Set command properties based on metadata from module
                if ($metadata) {
                    if ($metadata.CommandName) {
                        $cmd.Name = $metadata.CommandName
                    } else {
                        $cmd.name = $command.Name
                    }
                    $cmd.KeepHistory = $metadata.KeepHistory
                    $cmd.HideFromHelp = $metadata.HideFromHelp

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

                    # if ($metadata.TriggerType -eq 'Regex') {
                    #     $cmd.Trigger.Type = 'Regex'
                    #     $cmd.Trigger.Trigger = $metadata.Regex
                    # }

                    if ($metadata.MessageType) {
                        $cmd.Trigger.MessageType = $metadata.MessageType
                    }
                    if ($metadata.MessageSubtype) {
                        $cmd.Trigger.MessageSubtype = $metadata.MessageSubtype
                    }
                } else {
                    $cmd.Name = $command.Name
                    $cmd.Trigger = [Trigger]::new('Command', $command.Name)
                }

                $cmd.Description = $cmdHelp.Synopsis.Trim()
                $cmd.ManifestPath = $manifestPath
                $cmd.FunctionInfo = $command

                if ($cmdHelp.examples) {
                    $cmd.HelpText = $cmdHelp.examples[0].example[0].code.Trim()
                }
                $cmd.ModuleCommand = "$ModuleName\$($command.Name)"
                $cmd.AsJob = $AsJob

                # Add the desired roles for this command
                # This assumes that the roles have already been loaded in
                # to the role manager when the plugin was loaded
                if ($cmdHelp.Role) {
                    $rolesForCmd = @($this.GetRoleFromModuleCommand($cmdHelp))
                    foreach($r in $rolesForCmd) {
                        $role = $this.RoleManager.GetRole($r)
                        if ($role) {
                            $this.Logger.Info([LogMessage]::new("[PluginManager:CreatePluginFromModuleManifest] Adding role [$($role.Name)] to command [$($command.Name)]"))
                            $cmd.AddRole($role)
                        } else {
                            $this.Logger.Info([LogMessage]::new("[PluginManager:CreatePluginFromModuleManifest] Couldn't get role [$($role.Name)] for command [$($command.Name)]"))
                        }
                    }
                }

                # If this is a subcommand, attach it to the primary command
                # Subcommands will also be in the plugin manager command list
                # and can be invoked directly with a fully qualified command name as well (plugin:command-subcommand)
                # if ($isSubcommand) {
                #     $cmd.Trigger.Type = [TriggerType]::Regex
                #     $cmd.Trigger.Trigger = ("^$subCommandTrigger").Replace(' ', '\s')
                #     $primaryCommand = $plugin.Commands[$primaryCommandName]
                #     if ($primaryCommand) {
                #         if (-not $primaryCommand.Subcommands.ContainsKey($command.Name)) {
                #             #$cmd.Name = $subCommandName
                #             $this.Logger.Log([LogMessage]::new("[PluginManager:CreatePluginFromModuleManifest] Adding command [$($command.Name)] as a subcommand to [$primaryCommandName] "), [LogType]::System)
                #             $primaryCommand.Subcommands.Add($command.Name, $cmd)
                #         }
                #     } else {
                #         # Primary command not found
                #     }
                # }

                $plugin.AddCommand($cmd)
            }
            $this.LoadCommands()
            $this.SaveState()
        }
    }

    [PoshBot.BotCommand]GetCommandMetadata([System.Management.Automation.FunctionInfo]$Command) {
        $attrs = $Command.ScriptBlock.Attributes
        $botCmdAttr = $attrs | ForEach-Object {
            if ($_.TypeId.ToString() -eq 'PoshBot.BotCommand') {
                $_
            }
        }
        return $botCmdAttr
    }
    # Subcommands are identified with either a '-' or '_' in the
    # function name
    # [bool]IsSubcommand([string]$Name) {
    #     return ($Name.Contains('-') -or $Name.Contains('_'))
    # }

    # Return roles defined in module manifest
    [Role[]]GetRoleFromModuleManifest($Manifest) {
        $pluginRoles = New-Object System.Collections.ArrayList
        foreach ($role in $Manifest.PrivateData.Roles) {
            if ($role -is [string]) {
                $pluginRole = [Role]::new($role)
                $pluginRoles.Add($pluginRole)
            } elseIf ($role -is [hashtable]) {
                $pluginRole = [Role]::new($role.Name)
                if ($role.Description) {
                    $pluginRole.Description = $role.Description
                }
                $pluginRoles.Add($pluginRole)
            }
        }
        return $pluginRoles
    }

    [string[]]GetRoleFromModuleCommand($CmdHelp) {
        if ($CmdHelp.Role) {
            return @($CmdHelp.Role.split("`n") | ForEach-Object { $_.Split(',').Trim()})
        } else {
            return $null
        }
    }

    # Load in the built in plugins
    # Thee will be marked so that they DON't execute in a PowerShell job
    # as they need access to the bot internals
    [void]LoadBuiltinPlugins() {
        $this.Logger.Info([LogMessage]::new('[PluginManager:LoadBuiltinPlugins] Loading builtin plugins'))
        $builtinPlugin = Get-Item -Path "$($this._PoshBotModuleDir)/Plugins/Builtin"
        $moduleName = $builtinPlugin.BaseName
        $manifestPath = Join-Path -Path $builtinPlugin.FullName -ChildPath "$moduleName.psd1"
        $this.CreatePluginFromModuleManifest($moduleName, $manifestPath, $false)
    }
}
