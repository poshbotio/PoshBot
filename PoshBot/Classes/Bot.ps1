
class Bot {

    # Friendly name for the bot
    [string]$Name

    # The backend system for this bot (Slack, HipChat, etc)
    [Backend]$Backend

    hidden [string]$_PoshBotDir

    [StorageProvider]$Storage

    [PluginManager]$PluginManager

    [RoleManager]$RoleManager

    [CommandExecutor]$Executor

    # Queue of messages from the chat network to process
    [System.Collections.Queue]$MessageQueue = (New-Object System.Collections.Queue)

    [BotConfiguration]$Configuration

    hidden [Logger]$_Logger

    hidden [System.Diagnostics.Stopwatch]$_Stopwatch

    hidden [System.Collections.Arraylist] $_PossibleCommandPrefixes = (New-Object System.Collections.ArrayList)

    Bot([Backend]$Backend, [string]$PoshBotDir, [BotConfiguration]$Config) {
        $this.Name = $config.Name
        $this.Backend = $Backend
        $this._PoshBotDir = $PoshBotDir
        $this.Storage = [StorageProvider]::new($Config.ConfigurationDirectory)
        $this.Initialize($Config)
    }

    Bot([string]$Name, [Backend]$Backend, [string]$PoshBotDir, [string]$ConfigPath) {
        $this.Name = $Name
        $this.Backend = $Backend
        $this._PoshBotDir = $PoshBotDir
        $this.Storage = [StorageProvider]::new((Split-Path -Path $ConfigPath -Parent))
        $config = Get-PoshBotConfiguration -Path $ConfigPath
        $this.Initialize($config)
    }

    [void]Initialize([BotConfiguration]$Config) {
        if ($null -eq $Config) {
            $this.LoadConfiguration()
        } else {
            $this.Configuration = $Config
        }
        $this._Logger = [Logger]::new($this.Configuration.LogDirectory, $this.Configuration.LogLevel)
        $this.RoleManager = [RoleManager]::new($this.Backend, $this.Storage, $this._Logger)
        $this.PluginManager = [PluginManager]::new($this.RoleManager, $this.Storage, $this._Logger, $this._PoshBotDir)
        $this.Executor = [CommandExecutor]::new($this.RoleManager)
        $this.GenerateCommandPrefixList()

        # Add internal plugin directory and user-defined plugin directory to PSModulePath
        if (-not [string]::IsNullOrEmpty($this.Configuration.PluginDirectory)) {
            $internalPluginDir = Join-Path -Path $this._PoshBotDir -ChildPath 'Plugins'
            $modulePaths = $env:PSModulePath.Split(';')
            if ($modulePaths -notcontains $internalPluginDir) {
                $env:PSModulePath = $internalPluginDir + ';' + $env:PSModulePath
            }
            if ($modulePaths -notcontains $this.Configuration.PluginDirectory) {
                $env:PSModulePath = $this.Configuration.PluginDirectory + ';' + $env:PSModulePath
            }
        }

        # Set PS repository to trusted
        foreach ($repo in $this.Configuration.PluginRepository) {
            if (Get-PSRepository -Name $repo -Verbose:$false -ErrorAction SilentlyContinue) {
                Set-PSRepository -Name $repo -Verbose:$false -InstallationPolicy Trusted
            } else {
                [LogSeverity]::Error, "[Bot:Initialize] PowerShell repository [$repo)] is not defined"
            }
        }

        # Load in plugins listed in configuration
        if ($this.Configuration.ModuleManifestsToLoad.Count -gt 0) {
            $this._Logger.Info([LogMessage]::new('[Bot:Initialize] Loading in plugins from configuration'))
            foreach ($manifestPath in $this.Configuration.ModuleManifestsToLoad) {
                if (Test-Path -Path $manifestPath) {
                    $this.PluginManager.InstallPlugin($manifestPath, $false)
                } else {
                    $this._Logger.Info(
                        [LogMessage]::new(
                            [LogSeverity]::Warning, "[Bot:Initialize] Could not find manifest at [$manifestPath]"
                        )
                    )
                }
            }
        }
    }

    [void]LoadConfiguration() {
        $botConfig = $this.Storage.GetConfig($this.Name)
        if ($botConfig) {
            $this.Configuration = $botConfig
        } else {
            $this.Configuration = [BotConfiguration]::new()
            $hash = @{}
            $this.Configuration | Get-Member -MemberType Property | ForEach-Object {
                $hash.Add($_.Name, $this.Configuration.($_.Name))
            }
            $this.Storage.SaveConfig('Bot', $hash)
        }
    }

    # Start the bot
    [void]Start() {
        $this._Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $this._Logger.Info([LogMessage]::new('[Bot:Start] Start your engines'))

        try {
            $this.Connect()

            # Start the loop to receive and process messages from the backend
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            $this._Logger.Info([LogMessage]::new('[Bot:Start] Beginning message processing loop'))
            while ($this.Backend.Connection.Connected) {

                # Receive message and add to queue
                $this.ReceiveMessage()

                # Determine if message is for bot and handle as necessary
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
            $this._Logger.Info([LogMessage]::new([LogSeverity]::Error, "[Bot:Start] Exception [$($_.Exception.Message)]", $errJson))
        } finally {
            $this.Disconnect()
        }
    }

    # Connect the bot to the chat network
    [void]Connect() {
        $this._Logger.Verbose([LogMessage]::new('[Bot:Connect] Connecting to backend chat network'))
        $this.Backend.Connect()

        # That that we're connected, resolve any bot administrators defined in
        # configuration to their IDs and add to the [admin] role
        foreach ($admin in $this.Configuration.BotAdmins) {
            if ($adminId = $this.RoleManager.ResolveUserToId($admin)) {
                try {
                    $this.RoleManager.AddUserToGroup($adminId, 'Admin')
                } catch {
                    Write-Error $_
                }
            } else {
                $this._Logger.Info([LogMessage]::new([LogSeverity]::Warning, "[Bot:Connect] Unable to resolve ID for admin [$admin]"))
            }
        }
    }

    # Disconnect the bot from the chat network
    [void]Disconnect() {
        $this._Logger.Verbose([LogMessage]::new('[Bot:Disconnect] Disconnecting from backend chat network'))
        $this.Backend.Disconnect()
    }

    # Receive an event from the backend chat network
    [Message]ReceiveMessage() {
        $msg = $this.Backend.ReceiveMessage()
        # The backend MAY return a NULL message. Ignore it
        if ($msg) {
            $this._Logger.Debug([LogMessage]::new('[Bot:ReceiveMessage] Received bot message from chat network. Adding to message queue.', $msg))
            $this.MessageQueue.Enqueue($msg)
        }
        return $msg
    }

    [bool]IsBotCommand([Message]$Message) {
        $firstWord = ($Message.Text -split ' ')[0]
        foreach ($prefix in $this._PossibleCommandPrefixes ) {
            if ($firstWord -match "^$prefix") {
                $this._Logger.Debug([LogMessage]::new('[Bot:IsBotCommand] Message is a bot command.'))
                return $true
            }
        }
        return $false
    }

    # Pull message off queue and pass to message handler
    [void]ProcessMessageQueue() {
        if ($this.MessageQueue.Count -gt 0) {
            while ($this.MessageQueue.Count -ne 0) {
                $msg = $this.MessageQueue.Dequeue()
                $this._Logger.Debug([LogMessage]::new('[Bot:ProcessMessageQueue] Dequeued message', $msg))
                $this.HandleMessage($msg)
            }
        }
    }

    # Determine if the message received from the backend
    # is something the bot should act on
    [void]HandleMessage([Message]$Message) {
        # If message is intended to be a bot command
        # if this is false, and a trigger match is not found
        # then the message is just normal conversation that didn't
        # match a regex trigger. In that case, don't respond with an
        # error that we couldn't find the command
        $isBotCommand = $this.IsBotCommand($Message)
        $cmdSearch = $true
        if (-not $isBotCommand) {
            $cmdSearch = $false
            $this._Logger.Debug([LogMessage]::new('[Bot:HandleMessage] Message is not a bot command. Command triggers WILL NOT be searched.'))
        } else {
            # The message is intended to be a bot command
            $Message = $this.TrimPrefix($Message)
        }

        $commandString = $Message.Text
        $parsedCommand = [CommandParser]::Parse($commandString, $Message)
        $this._Logger.Debug([LogMessage]::new('[Bot:HandleMessage] Parsed bot command', $parsedCommand))
        $response = [Response]::new()
        $response.MessageFrom = $Message.From
        $response.To = $Message.To

        # Match parsed command to a command in the plugin manager
        $pluginCmd = $this.PluginManager.MatchCommand($parsedCommand, $cmdSearch)
        if ($pluginCmd) {

            # Add the name of the plugin to the parsed command
            # if it wasn't fully qualified to begin with
            if ([string]::IsNullOrEmpty($parsedCommand.Plugin)) {
                $parsedCommand.Plugin = $pluginCmd.Plugin.Name
            }

            # Pass in the bot to the module command.
            # We need this for builtin commands
            if ($pluginCmd.Plugin.Name -eq 'Builtin') {
                $parsedCommand.NamedParameters.Add('Bot', $this)
            }

            # Inspect the command and find any parameters that should
            # be provided from the bot configuration
            # Insert these as named parameters
            $configProvidedParams = $this.GetConfigProvidedParameters($pluginCmd)
            foreach ($cp in $configProvidedParams.GetEnumerator()) {
                if (-not $parsedCommand.NamedParameters.ContainsKey($cp.Name)) {
                    $parsedCommand.NamedParameters.Add($cp.Name, $cp.Value)
                }
            }

            $result = $this.DispatchCommand($pluginCmd, $parsedCommand, $Message.From)
            if (-not $result.Success) {

                # Was the command not authorized?
                if (-not $result.Authorized) {
                    $response.Severity = [Severity]::Warning
                    $response.Data = New-PoshBotCardResponse -Type Warning -Text "You do not have authorization to run command [$($pluginCmd.Command.Name)] :(" -Title 'Command Unauthorized'
                } else {
                    # TODO
                    # Handle this better
                    $response.Severity = [Severity]::Error
                    if ($result.Errors.Count -gt 0) {
                        $response.Data = $result.Errors | ForEach-Object {
                            if ($_.Exception) {
                                New-PoshBotCardResponse -Type Error -Text $_.Exception.Message -Title 'Command Exception'
                            } else {
                                New-PoshBotCardResponse -Type Error -Text $_ -Title 'Command Exception'
                            }
                        }
                    } else {
                        $response.Data = New-PoshBotCardResponse -Type Error -Text 'Something bad happened :(' -Title 'Command Error'
                    }
                }
            } else {
                foreach ($r in $result.Output) {
                    if (($r.PSObject.TypeNames[0] -eq 'PoshBot.Text.Response') -or ($r.PSObject.TypeNames[0] -eq 'PoshBot.Card.Response')) {
                        $response.Data += $r
                    } else {
                        $response.Text += $($r | Format-List * | Out-String)
                    }
                }
                #$response.Text = $($result.Output | Format-List * | Out-String)
            }
        } else {
            if ($isBotCommand) {
                $msg = "No command found matching [$commandString]"
                $this._Logger.Info([LogMessage]::new([LogSeverity]::Warning, $msg, $parsedCommand))
                # Only respond with command not found message if configuration allows it.
                if (-not $this.Configuration.MuteUnknownCommand) {
                    $response.Severity = [Severity]::Warning
                    $response.Data = New-PoshBotCardResponse -Type Warning -Text $msg
                }
            }
        }

        # Send response back to user in private (DM) channel if this command
        # is marked to devert responses
        if ($pluginCmd) {
            if ($this.Configuration.SendCommandResponseToPrivate -Contains $pluginCmd.ToString()) {
                $this._Logger.Info([LogMessage]::new("[Bot:HandleMessage] Deverting response from command [$pluginCmd.ToString()] to private channel"))
                $Response.To = "@$($this.RoleManager.ResolveUserToId($Message.From))"
            }
        }

        $this.SendMessage($response)
    }

    # Dispatch the command to the executor
    [CommandResult]DispatchCommand([PluginCommand]$PluginCmd, [ParsedCommand]$ParsedCommand, [string]$CallerId) {
        $result = $this.Executor.ExecuteCommand($PluginCmd, $ParsedCommand, $CallerId)
        return $result
    }

    # Trim the command prefix or any alternate prefix or seperators off the message
    # as we won't need them anymore.
    [Message]TrimPrefix([Message]$Message) {
        if (-not [string]::IsNullOrEmpty($Message.Text)) {
            $Message.Text = $Message.Text.Trim()
            $firstWord = ($Message.Text -split ' ')[0]

            foreach ($prefix in $this._PossibleCommandPrefixes) {
                if ($firstWord -match "^$prefix") {
                    $Message.Text = $Message.Text.TrimStart($prefix).Trim()
                }
            }
        }
        return $Message
    }

    [void]GenerateCommandPrefixList() {
        $this._PossibleCommandPrefixes.Add($this.Configuration.CommandPrefix)
        foreach ($alternatePrefix in $this.Configuration.AlternateCommandPrefixes) {
            $this._PossibleCommandPrefixes.Add($alternatePrefix)
            foreach ($seperator in ($this.Configuration.AlternateCommandPrefixSeperators)) {
                $prefixPlusSeperator = "$alternatePrefix$seperator"
                $this._PossibleCommandPrefixes.Add($prefixPlusSeperator)
            }
        }
    }

    # Send the response to the backend to execute
    [void]SendMessage([Response]$Response) {
        $this.Backend.SendMessage($Response)
    }

    # Get any parameters with the
    [hashtable]GetConfigProvidedParameters([PluginCommand]$PluginCmd) {

        $command = $PluginCmd.Command.FunctionInfo

        $this._Logger.Debug([LogMessage]::new("[Bot:GetConfigProvidedParameters] Inspecting command [$($PluginCmd.ToString())] for configuration-provided parameters"))
        $configParams = foreach($param in $Command.Parameters.GetEnumerator() | Select-Object -ExpandProperty Value) {
            foreach ($attr in $param.Attributes) {
                if ($attr.GetType().ToString() -eq 'PoshBot.FromConfig') {
                    [ConfigProvidedParameter]::new($attr, $param)
                }
            }
        }

        $configProvidedParams = @{}
        if ($configParams) {
            $pluginConfig = $this.Configuration.PluginConfiguration[$PluginCmd.Plugin.Name]
            if ($pluginConfig) {
                $this._Logger.Info([LogMessage]::new("[Bot:GetConfigProvidedParameters] Inspecting bot configuration for parameter values matching command [$($PluginCmd.ToString())]"))
                foreach ($cp in $configParams) {

                    if (-not [string]::IsNullOrEmpty($cp.Metadata.Name)) {
                        $configParamName = $cp.Metadata.Name
                    } else {
                        $configParamName = $cp.Parameter.Name
                    }

                    if ($pluginConfig.ContainsKey($configParamName)) {
                        $configProvidedParams.Add($cp.Parameter.Name, $pluginConfig[$configParamName])
                    }
                }
            } else {
                # No plugin configuration defined.
                # Unable to provide values for these parameters
            }
        }

        return $configProvidedParams
    }
}
