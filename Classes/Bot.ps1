
class Bot {

    # Friendly name for the bot
    [string]$Name

    # The backend system for this bot (Slack, HipChat, etc)
    [Backend]$Backend

    # List of loaded plugins
    [hashtable]$Plugins = @{}

    hidden [string]$_PoshBotDir

    # List of commands available from plugins
    [hashtable]$Commands = @{}

    # List of roles loaded from plugins
    [hashtable]$Roles = @{}

    # Queue of messages from the chat network to process
    [System.Collections.Queue]$MessageQueue = (New-Object System.Collections.Queue)

    [string]$CommandPrefix = '!'

    [string[]]$BuildinCommands = @('help', 'status')

    [bool]$ShouldRun = $true

    [Logger]$Logger

    [System.Diagnostics.Stopwatch]$Stopwatch

    Bot([string]$Name) {
        $this.Name = $Name
        $this.Logger = [Logger]::new()
    }

    Bot([string]$Name, [string]$LogPath) {
        $this.Name = $Name
        $this.Logger = [Logger]::new($LogPath)
    }

    # Start the bot
    [void]Start() {
        $this.Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $this.Logger.Log([LogMessage]::new('[Bot:Start] Start your engines'), [LogType]::System)

        try {
            $this.Connect()

            # Start the loop to receive and process messages from the backend
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            $this.Logger.Log([LogMessage]::new('[Bot:Start] Beginning message processing loop'), [LogType]::System)
            while ($this.ShouldRun -and $this.Backend.Connection.Connected) {

                # Receive message and add to queue
                $this.ReceiveMessage()
                #$this.EventQueue.Enqueue($e)

                $this.ProcessMessageQueue()

                Start-Sleep -Milliseconds 100

                # Send a ping every 5 seconds
                if ($sw.Elapsed.TotalSeconds -gt 5) {
                    $this.Backend.Ping()
                    $sw.Reset()
                }
            }
        } catch {
            Write-Error $_
            $errJson = [ExceptionFormatter]::ToJson($_)
            $msg = [LogMessage]::new("[Bot:Start] Exception [$($_.Exception.Message)]", $errJson)
            $this.Logger.Log($msg, [LogType]::System)
            $this.Logger.Log($msg, [LogType]::Debug)
        } finally {
            $this.Disconnect()
        }
    }

    # Connect the bot to the chat network
    [void]Connect() {
        $this.Logger.Log([LogMessage]::new('[Bot:Connect] Connecting to backend chat network'), [LogType]::System)
        $this.Backend.Connect()
    }

    # Disconnect the bot from the chat network
    [void]Disconnect() {
        $this.Logger.Log([LogMessage]::new('[Bot:Disconnect] Disconnecting from backend chat network'), [LogType]::System)
        $this.Backend.Disconnect()
    }

    [void]AttachBackend([Backend]$Backend) {
        $this.Logger.Log([LogMessage]::new('[Bot:AttachBackend] Attaching backend'), [LogType]::System)
        $this.Backend = $Backend
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
                        $this.Logger.Log([LogMessage]::new("[Bot:LoadCommands] Loading command [$fullyQualifiedCommandName]"), [LogType]::System)
                        $this.Commands.Add($fullyQualifiedCommandName, $command)
                    }

                    ## If this command has an associated trigger regex, load that as well
                    #if (($null -ne $command.Trigger) -and (-not $this.Triggers.ContainsKey($command.Trigger))) {
                    #    $this.Triggers.Add($command.Trigger, $fullyQualifiedCommandName)
                    #}
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
            $this.Logger.Log([LogMessage]::new("[Bot:LoadCommands] Removing command [$_]. Plugin has either been removed or is deactivated."), [LogType]::System)
            $this.Commands.Remove($_)
            #$this.Triggers.Remove($_)
        }
    }

    [void]LoadRoles() {
        $allRoles = New-Object System.Collections.ArrayList
        foreach ($pluginKey in $this.Plugins.Keys) {
            $plugin = $this.Plugins[$pluginKey]
            if ($plugin.Enabled) {
                foreach ($roleKey in $plugin.Roles.Keys) {
                    $role =  $plugin.Roles[$roleKey]
                    $allRoles.Add($roleKey)
                    if (-not $this.Roles.ContainsKey($roleKey)) {
                        $this.Logger.Log([LogMessage]::new("[Bot:LoadRoles] Loading role [$roleKey] from plugin [$($plugin.Name)]"), [LogType]::System)
                        $this.Roles.Add($roleKey, $role)
                    }
                }
            }
        }

        # Remove any commands that are not in any of the loaded (and active) plugins
        $remove = New-Object System.Collections.ArrayList
        foreach($r in $this.Roles.Keys) {
            if (-not $allRoles.Contains($r)) {
                $remove.Add($r)
            }
        }
        $remove | ForEach-Object {
            $this.Logger.Log([LogMessage]::new("[Bot:LoadCommands] Removing role [$_]. Plugin has either been removed or is deactivated."), [LogType]::System)
            $this.Roles.Remove($_)
            #$this.Triggers.Remove($_)
        }
    }

    # Add a plugin to the bot
    [void]AddPlugin([Plugin]$Plugin) {
        if (-not $this.Plugins.ContainsKey($Plugin.Name)) {
            $this.Logger.Log([LogMessage]::new("[Bot:AddPlugin] Attaching plugin [$($Plugin.Name)]"), [LogType]::System)
            $this.Plugins.Add($Plugin.Name, $Plugin)
        }

        # Reload commands and role from all currently loading (and active) plugins
        $this.LoadCommands()
        $this.LoadRoles()
    }

    # Remove a plugin from the bot
    [void]RemovePlugin([Plugin]$Plugin) {
        if ($this.Plugins.ContainsKey($Plugin.Name)) {
            $this.Logger.Log([LogMessage]::new("[Bot:RemovePlugin] Removing plugin [$Plugin.Name]"), [LogType]::System)
            $this.Plugins.Remove($Plugin.Name)
        }

        # Reload commands from all currently loading (and active) plugins
        $this.LoadCommands()
    }

    # Activate a plugin
    [void]ActivatePlugin([Plugin]$Plugin) {
        $p = $this.Plugins[$Plugin.Name]
        if ($p) {
            $this.Logger.Log([LogMessage]::new("[Bot:ActivatePlugin] Activating plugin [$Plugin.Name]"), [LogType]::System)
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
            $this.Logger.Log([LogMessage]::new("[Bot:DeactivatePlugin] Deactivating plugin [$Plugin.Name]"), [LogType]::System)
            $p.Deactivate()
        } else {
            throw [PluginNotFoundException]::New("Plugin [$($Plugin.Name)] is not loaded in bot")
        }

        # Reload commands from all currently loading (and active) plugins
        $this.LoadCommands()
    }

    # Receive an event from the backend chat network
    [Message]ReceiveMessage() {
        $msg = $this.Backend.ReceiveMessage()
        # The backend MAY return a NULL message. Ignore it
        if ($msg) {
            # If the message is a bot command or another type of message we should care
            # about, add it to the message queue for processing
            #if ($this.IsBotCommand($msg)) {
                $this.Logger.Log([LogMessage]::new('[Bot:ReceiveMessage] Received bot message from chat network. Adding to message queue.', $msg), [LogType]::System)
                $this.Logger.Log([LogMessage]::new('[Bot:Received message]', $msg), [LogType]::Receive)
                $this.MessageQueue.Enqueue($msg)
            #} else {
                # TODO
                # Some other type of message we are watching for
            #}
        }
        return $msg
    }

    # [bool]IsBotCommand([Message]$Message) {
    #     $firstWord = ($Message.Text -split ' ')[0]
    #     $isBotCommand = $firstWord -Match "^$($this.CommandPrefix)"
    #     $match = $false
    #     if ($isBotCommand) {
    #         $match = $true
    #         $this.Logger.Log([LogMessage]::new('[Bot:IsBotCommand] Message is a bot command.'), [LogType]::System)
    #     } else {

    #         # foreach ($trigger in $this.Triggers.Keys) {
    #         #     if ($Message.Text -Match $trigger) {
    #         #         $match = $true
    #         #         $this.Logger.Log([LogMessage]::new("[Bot:IsBotCommand] Message matches trigger [$trigger]."), [LogType]::System)
    #         #         break
    #         #     }
    #         # }
    #     }

    #     return $match
    # }

    [void]ProcessMessageQueue() {
        if ($this.MessageQueue.Count -gt 0) {
            while ($this.MessageQueue.Count -ne 0) {
                # Pull message off queue and pass to message handler
                $msg = $this.MessageQueue.Dequeue()
                $this.Logger.Log([LogMessage]::new('[Bot:ProcessMessageQueue] Dequeued message', $msg), [LogType]::System)
                $this.HandleMessage($msg)
            }
        }
    }

    # Determine if the message received from the backend
    # is something the bot should act on
    [void]HandleMessage([Message]$Message) {
        # If the message text starts with our bot prefix (!) then assume it's a message
        # for the bot and look for a command matching it
        if ($Message.Text) {
            $commandString = $Message.Text.TrimStart($this.CommandPrefix)
            $parsedCommand = [CommandParser]::Parse($commandString)
            $this.Logger.Log([LogMessage]::new('[Bot:HandleMessage] Parsed bot command', $parsedCommand), [LogType]::System)

            $response = [Response]::new()
            $response.To = $Message.To
            $cmd = $this.MatchCommand($parsedCommand)
            if ($cmd) {
                $plugin = $this.GetPluginForCommand($cmd)
                if ($plugin) {

                    # Pass in the bot to the module command.
                    # We need this for builtin commands
                    if ($Plugin.Name -eq 'Builtin') {
                        $parsedCommand.NamedParameters.Add('Bot', $this)
                    }

                    $result = $this.DispatchCommand($cmd, $parsedCommand, $plugin, $Message.From)

                    if (-not $result.Success) {

                        # Was the command not authorized?
                        if (-not $result.Authorized) {
                            $response.Severity = [Severity]::Warning
                            $response.Text = "You do not have authorization to run command [$($cmd.Name)] :("
                            #$msgText = "You do not have authorization to run command [$($cmd.Name)] :("
                        } else {
                            # TODO
                            # Handle this better
                            $response.Severity = [Severity]::Error
                            $response.Text = '[Bot:HandleMessage] Something bad happened :('
                            #$msgText = '[Bot:HandleMessage] Something bad happended :('
                        }
                    } else {
                        $response.Text = $($result.Output | Format-List * | Out-String)
                        #$msgText = $($result.Output | Format-List * | Out-String)
                    }
                    $this.SendMessage($response)
                    #$this.SendMessage($msgText, $Message.To)
                }
            } else {
                $response.Severity = [Severity]::Warning
                $response.Text = "No command found matching [$commandString]"
                $this.SendMessage($response)
            }
        }
    }

    # Match a pared command to a command in one of the currently loaded plugins
    [Command]MatchCommand([ParsedCommand]$ParsedCommand) {

        # Check builtin commands first
        $builtinPlugin = $this.Plugins['Builtin']
        foreach ($commandKey in $builtinPlugin.Commands.Keys) {
            $command = $builtinPlugin.Commands[$commandKey]
            if ($command.TriggerMatch($ParsedCommand)) {
                $this.Logger.Log([LogMessage]::new("[Bot:MatchCommand] Matched parsed command [$($ParsedCommand.Plugin)`:$($ParsedCommand.Command)] to builtin command [Builtin:$commandKey]"), [LogType]::System)
                return $command
            }
        }

        # If parsed command is fully qualified with <plugin:command> syntax. Just look in that plugin
        if (($ParsedCommand.Plugin -ne [string]::Empty) -and ($ParsedCommand.Command -ne [string]::Empty)) {
            $plugin = $this.Plugins[$ParsedCommand.Plugin]
            if ($plugin) {
                foreach ($commandKey in $plugin.Commands.Keys) {
                    $command = $plugin.Commands[$commandKey]
                    if ($command.TriggerMatch($ParsedCommand)) {
                        $this.Logger.Log([LogMessage]::new("[Bot:MatchCommand] Matched parsed command [$($ParsedCommand.Plugin)`:$($ParsedCommand.Command)] to plugin command [$($plugin.Name)`:$commandKey]"), [LogType]::System)
                        return $command
                    }
                }
                $this.Logger.Log([LogMessage]::new("[Bot:MatchCommand] Unable to match parsed command [$($ParsedCommand.Plugin)`:$($ParsedCommand.Command)] to a command in plugin [$($plugin.Name)]"), [LogType]::System)
            } else {
                $this.Logger.Log([LogMessage]::new("[Bot:MatchCommand] Unable to match parsed command [$($ParsedCommand.Plugin)`:$($ParsedCommand.Command)] to a plugin command"), [LogType]::System)
                return $null
            }
        } else {
            # Check all regular plugins/commands now
            foreach ($pluginKey in $this.Plugins.Keys) {
                $plugin = $this.Plugins[$pluginKey]
                foreach ($commandKey in $plugin.Commands.Keys) {
                    $command = $plugin.Commands[$commandKey]
                    if ($command.TriggerMatch($ParsedCommand)) {
                        $this.Logger.Log([LogMessage]::new("[Bot:MatchCommand] Matched parsed command [$($ParsedCommand.Plugin)`:$($ParsedCommand.Command)] to plugin command [$pluginKey`:$commandKey]"), [LogType]::System)
                        return $command
                    }
                }
            }
        }

        $this.Logger.Log([LogMessage]::new("[Bot:MatchCommand] Unable to match parsed command [$($ParsedCommand.Plugin)`:$($ParsedCommand.Command)] to a plugin command"), [LogType]::System)
        return $null
    }

    # Dispatch the command to the plugin for execution
    [CommandResult]DispatchCommand([Command]$Command, [ParsedCommand]$ParsedCommand, [Plugin]$Plugin, [string]$CallerId) {
        $logMsg = [LogMessage]::new("[Bot:DispatchCommand] Dispatching command [$($Command.Name)] to plugin [$($Plugin.Name)] with caller ID [$CallerId]")
        $this.Logger.Log($logMsg, [LogType]::System)
        $this.Logger.Log($logMsg, [LogType]::Command)
        $result = $Plugin.InvokeCommand($Command, $ParsedCommand, $CallerId)
        Write-Verbose "[Bot:DispatchCommand] Command result: $($result | Format-List * | Out-String)"
        $logMsg = [LogMessage]::new('[Bot:DispatchCommand] Command result', $result)
        $this.Logger.Log($logMsg, [LogType]::System)
        $this.Logger.Log($logMsg, [LogType]::Command)
        return $result

        # Determine how to respond back to the chat network now that
        # the command has completed. This is up to the command
        # TODO
    }

    [Plugin]GetPluginForCommand([Command]$Command) {
        $this.Logger.Log([LogMessage]::new("[Bot:GetPluginForCommand] Resolving plugin for command [$($Command.Name)]"), [LogType]::System)

        # Check regular plugins
        foreach ($pluginKey in $this.Plugins.Keys) {
            $plugin = $this.Plugins[$pluginKey]
            foreach ($commandKey in $plugin.Commands.Keys) {
                if ($plugin.Commands[$commandKey].Name -eq $Command.Name) {
                    $matchingPlugin = $plugin
                    $this.Logger.Log([LogMessage]::new("[Bot:GetPluginForCommand] Found plugin [$($matchingPlugin.Name)]"), [LogType]::System)
                    return $matchingPlugin
                }
            }
        }

        $this.Logger.Log([LogMessage]::new("[Bot:GetPluginForCommand] Unable to match command [$($Command.Name)] to a plugin"), [LogType]::System)
        return $null
    }

    # Format the response
    [void]FormatResponse([Message]$Message) {

        # Let the specific backend deal with format the response
        $formatedMessage = $this.Backend.FormatResponse([Message]$Message)

        $this.SendResponse($formatedMessage)
    }

    # Send the response to the backend to execute
    [void]SendMessage([Response]$Response) {
        $this.Backend.SendMessage($Response)
    }

    [void]SendMessage([Card]$Response) {
        $this.Backend.SendMessage($Response)
    }

    [void]LoadBuiltinPlugins() {
        $pluginsToLoad = Get-ChildItem -Path "$($this._PoshBotDir)/Plugins" -Directory
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
                    $plugin.AddCommand($cmd)
                }

                $this.AddPlugin($plugin)
            }
        }
    }
}

function New-PoshBotInstance {
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        [string]$Name,

        [Backend]$Backend
    )

    $bot = [Bot]::new($Name)
    $bot._PoshBotDir = $script:moduleRoot
    $bot.LoadBuiltinPlugins()

    if ($Backend) {
        $bot.AttachBackend($Backend)
    }

    return $bot
}

function Add-PoshBotPlugin {
    [cmdletbinding()]
    param(
        [parameter(Mandatory, ValueFromPipeline)]
        [Alias('Bot')]
        [Bot]$InputObject,

        [parameter(Mandatory)]
        [Plugin]$Plugin
    )

    Write-Verbose -Message "Adding plugin [$($Plugin.Name)] to bot"
    $InputObject.AddPlugin($Plugin)
}

