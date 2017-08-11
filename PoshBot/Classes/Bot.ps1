
class Bot : BaseLogger {

    # Friendly name for the bot
    [string]$Name

    # The backend system for this bot (Slack, HipChat, etc)
    [Backend]$Backend

    hidden [string]$_PoshBotDir

    [StorageProvider]$Storage

    [PluginManager]$PluginManager

    [RoleManager]$RoleManager

    [CommandExecutor]$Executor

    [Scheduler]$Scheduler

    # Queue of messages from the chat network to process
    [System.Collections.Queue]$MessageQueue = (New-Object System.Collections.Queue)

    [BotConfiguration]$Configuration

    hidden [System.Diagnostics.Stopwatch]$_Stopwatch

    hidden [System.Collections.Arraylist] $_PossibleCommandPrefixes = (New-Object System.Collections.ArrayList)

    Bot([Backend]$Backend, [string]$PoshBotDir, [BotConfiguration]$Config)
        : base($Config.LogDirectory, $Config.LogLevel, $Config.MaxLogSizeMB, $Config.MaxLogsToKeep) {

        $this.Name = $config.Name
        $this.Backend = $Backend
        $this._PoshBotDir = $PoshBotDir
        $this.Storage = [StorageProvider]::new($Config.ConfigurationDirectory, $this.Logger)
        $this.Initialize($Config)
    }

    Bot([string]$Name, [Backend]$Backend, [string]$PoshBotDir, [string]$ConfigPath)
        : base($Config.LogDirectory, $Config.LogLevel, $Config.MaxLogSizeMB, $Config.MaxLogsToKeep) {

        $this.Name = $Name
        $this.Backend = $Backend
        $this._PoshBotDir = $PoshBotDir
        $this.Storage = [StorageProvider]::new((Split-Path -Path $ConfigPath -Parent), $this.Logger)
        $config = Get-PoshBotConfiguration -Path $ConfigPath
        $this.Initialize($config)
    }

    [void]Initialize([BotConfiguration]$Config) {
        $this.LogInfo('Initializing bot')

        # Attach the logger to the backend
        $this.Backend.Logger = $this.Logger
        $this.Backend.Connection.Logger = $this.Logger

        if ($null -eq $Config) {
            $this.LoadConfiguration()
        } else {
            $this.Configuration = $Config
        }
        $this.RoleManager = [RoleManager]::new($this.Backend, $this.Storage, $this.Logger)
        $this.PluginManager = [PluginManager]::new($this.RoleManager, $this.Storage, $this.Logger, $this._PoshBotDir)
        $this.Executor = [CommandExecutor]::new($this.RoleManager, $this.Logger, $this)
        $this.Scheduler = [Scheduler]::new($this.Storage, $this.Logger)
        $this.GenerateCommandPrefixList()

        # Ugly hack alert!
        # Store the ConfigurationDirectory property in a script level variable
        # so the command class as access to it.
        $script:ConfigurationDirectory = $this.Configuration.ConfigurationDirectory

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
            if ($r = Get-PSRepository -Name $repo -Verbose:$false -ErrorAction SilentlyContinue) {
                if ($r.InstallationPolicy -ne 'Trusted') {
                    $this.LogVerbose("Setting PowerShell repository [$repo] to [Trusted]")
                    Set-PSRepository -Name $repo -Verbose:$false -InstallationPolicy Trusted
                }
            } else {
                $this.LogVerbose([LogSeverity]::Warning, "PowerShell repository [$repo)] is not defined on the system")
            }
        }

        # Load in plugins listed in configuration
        if ($this.Configuration.ModuleManifestsToLoad.Count -gt 0) {
            $this.LogInfo('Loading in plugins from configuration')
            foreach ($manifestPath in $this.Configuration.ModuleManifestsToLoad) {
                if (Test-Path -Path $manifestPath) {
                    $this.PluginManager.InstallPlugin($manifestPath, $false)
                } else {
                    $this.LogInfo([LogSeverity]::Warning, "Could not find manifest at [$manifestPath]")
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
        $this.LogInfo('Start your engines')

        try {
            $this.Connect()

            # Start the loop to receive and process messages from the backend
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            $this.LogInfo('Beginning message processing loop')
            while ($this.Backend.Connection.Connected) {

                # Receive message and add to queue
                $this.ReceiveMessage()

                # Get 0 or more scheduled jobs that need to be executed
                # and add to message queue
                $this.ProcessScheduledMessages()

                # Determine if message is for bot and handle as necessary
                $this.ProcessMessageQueue()

                # Receive any completed jobs and process them
                $this.ProcessCompletedJobs()

                Start-Sleep -Milliseconds 100

                # Send a ping every 5 seconds
                if ($sw.Elapsed.TotalSeconds -gt 5) {
                    $this.Backend.Ping()
                    $sw.Reset()
                }
            }
        } catch {
            $this.LogInfo([LogSeverity]::Error, "$($_.Exception.Message)", [ExceptionFormatter]::Summarize($_))
        } finally {
            $this.Disconnect()
        }
    }

    # Connect the bot to the chat network
    [void]Connect() {
        $this.LogVerbose('Connecting to backend chat network')
        $this.Backend.Connect()

        # That that we're connected, resolve any bot administrators defined in
        # configuration to their IDs and add to the [admin] role
        foreach ($admin in $this.Configuration.BotAdmins) {
            if ($adminId = $this.RoleManager.ResolveUsernameToId($admin)) {
                try {
                    $this.RoleManager.AddUserToGroup($adminId, 'Admin')
                } catch {
                    $this.LogInfo([LogSeverity]::Warning, "Unable to add [$admin] to [Admin] group", [ExceptionFormatter]::Summarize($_))
                }
            } else {
                $this.LogInfo([LogSeverity]::Warning, "Unable to resolve ID for admin [$admin]")
            }
        }
    }

    # Disconnect the bot from the chat network
    [void]Disconnect() {
        $this.LogVerbose('Disconnecting from backend chat network')
        $this.Backend.Disconnect()
    }

    # Receive messages from the backend chat network
    [void]ReceiveMessage() {
        foreach ($msg in $this.Backend.ReceiveMessage()) {
            $this.LogDebug('Received bot message from chat network. Adding to message queue.', $msg)
            $this.MessageQueue.Enqueue($msg)
        }
    }

    # Receive any messages from the scheduler that had their timer elapse and should be executed
    [void]ProcessScheduledMessages() {
        foreach ($msg in $this.Scheduler.GetTriggeredMessages()) {
            $this.LogDebug('Received scheduled message from scheduler. Adding to message queue.', $msg)
            $this.MessageQueue.Enqueue($msg)
        }
    }

    # Determine if message text is addressing the bot and should be
    # treated as a bot command
    [bool]IsBotCommand([Message]$Message) {
        $firstWord = ($Message.Text -split ' ')[0]
        foreach ($prefix in $this._PossibleCommandPrefixes ) {
            if ($firstWord -match "^$prefix") {
                $this.LogDebug('Message is a bot command')
                return $true
            }
        }
        return $false
    }

    # Pull message(s) off queue and pass to handler
    [void]ProcessMessageQueue() {
        while ($this.MessageQueue.Count -ne 0) {
            $msg = $this.MessageQueue.Dequeue()
            $this.LogDebug('Dequeued message', $msg)
            $this.HandleMessage($msg)
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
            $this.LogDebug('Message is not a bot command. Command triggers WILL NOT be searched.')
        } else {
            # The message is intended to be a bot command
            $Message = $this.TrimPrefix($Message)
        }

        $parsedCommand = [CommandParser]::Parse($Message)
        $this.LogDebug('Parsed bot command', $parsedCommand)

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

            $this.Executor.ExecuteCommand($PluginCmd, $ParsedCommand, $Message)
        } else {
            if ($isBotCommand) {
                $msg = "No command found matching [$($Message.Text)]"
                $this.LogInfo([LogSeverity]::Warning, $msg, $parsedCommand)
                # Only respond with command not found message if configuration allows it.
                if (-not $this.Configuration.MuteUnknownCommand) {
                    $response = [Response]::new()
                    $response.MessageFrom = $Message.From
                    $response.To = $Message.To
                    $response.Severity = [Severity]::Warning
                    $response.Data = New-PoshBotCardResponse -Type Warning -Text $msg
                    $this.SendMessage($response)
                }
            }
        }
    }

    # Get completed jobs, determine success/error, then return response to backend
    [void]ProcessCompletedJobs() {
        $completedJobs = $this.Executor.ReceiveJob()

        $count = $completedJobs.Count
        if ($count -ge 1) {
            $this.LogInfo("Processing [$count] completed jobs")
        }

        foreach ($cmdExecContext in $completedJobs) {
            $this.LogInfo("Processing job execution [$($cmdExecContext.Id)]")

            $response = [Response]::new()
            $response.MessageFrom = $cmdExecContext.Message.From
            $response.To = $cmdExecContext.Message.To

            if (-not $cmdExecContext.Result.Success) {
                # Was the command authorized?
                if (-not $cmdExecContext.Result.Authorized) {
                    $response.Severity = [Severity]::Warning
                    $response.Data = New-PoshBotCardResponse -Type Warning -Text "You do not have authorization to run command [$($cmdExecContext.Command.Name)] :(" -Title 'Command Unauthorized'
                    $this.LogInfo([LogSeverity]::Warning, 'Command unauthorized')
                } else {
                    $response.Severity = [Severity]::Error
                    if ($cmdExecContext.Result.Errors.Count -gt 0) {
                        $response.Data = $cmdExecContext.Result.Errors | ForEach-Object {
                            if ($_.Exception) {
                                New-PoshBotCardResponse -Type Error -Text $_.Exception.Message -Title 'Command Exception'
                            } else {
                                New-PoshBotCardResponse -Type Error -Text $_ -Title 'Command Exception'
                            }
                        }
                    } else {
                        $response.Data += New-PoshBotCardResponse -Type Error -Text 'Something bad happened :(' -Title 'Command Error'
                        $response.Data += $cmdExecContext.Result.Errors
                    }
                    $this.LogInfo([LogSeverity]::Error, "Errors encountered running command [$($cmdExecContext.FullyQualifiedCommandName)]", $cmdExecContext.Result.Errors)
                }
            } else {
                $this.LogVerbose('Command execution result', $cmdExecContext.Result)
                foreach ($resultOutput in $cmdExecContext.Result.Output) {
                    if ($null -ne $resultOutput) {
                        if ($this._IsCustomResponse($resultOutput)) {
                            $response.Data += $resultOutput
                        } else {
                            # If the response is a simple type, just display it as a string
                            # otherwise we need remove auto-generated properties that show up
                            # from deserialized objects
                            if ($this._IsPrimitiveType($resultOutput)) {
                                $response.Text += $resultOutput.ToString().Trim()
                            } else {
                                $deserializedProps = 'PSComputerName', 'PSShowComputerName', 'PSSourceJobInstanceId', 'RunspaceId'
                                $resultText = $resultOutput | Select-Object -Property * -ExcludeProperty $deserializedProps
                                $response.Text += ($resultText | Format-List -Property * | Out-String).Trim()
                            }
                        }
                    }
                }
            }

            # Write out this command execution to permanent storage
            if ($this.Configuration.LogCommandHistory) {
                $logMsg = [LogMessage]::new("[$($cmdExecContext.FullyQualifiedCommandName)] was executed by [$($cmdExecContext.Message.From)]", $cmdExecContext.Summarize())
                $cmdHistoryLogPath = Join-Path $this.Configuration.LogDirectory -ChildPath 'CommandHistory.log'
                $this.Log($logMsg, $cmdHistoryLogPath, $this.Configuration.CommandHistoryMaxLogSizeMB, $this.Configuration.CommandHistoryMaxLogsToKeep)
            }

            # Send response back to user in private (DM) channel if this command
            # is marked to devert responses
            if ($this.Configuration.SendCommandResponseToPrivate -contains $cmdExecContext.FullyQualifiedCommandName) {
                $this.LogInfo("Deverting response from command [$($cmdExecContext.FullyQualifiedCommandName)] to private channel")
                $response.To = "@$($this.RoleManager.ResolveUserIdToUserName($cmdExecContext.Message.From))"
            }

            $this.SendMessage($response)
            $this.LogInfo("Done processing command [$($cmdExecContext.FullyQualifiedCommandName)]")
        }
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

    # Create complete list of command prefixes so we can quickly
    # evaluate messages from the chat network and determine if
    # they are bot commands
    [void]GenerateCommandPrefixList() {
        $this._PossibleCommandPrefixes.Add($this.Configuration.CommandPrefix)
        foreach ($alternatePrefix in $this.Configuration.AlternateCommandPrefixes) {
            $this._PossibleCommandPrefixes.Add($alternatePrefix) > $null
            foreach ($seperator in ($this.Configuration.AlternateCommandPrefixSeperators)) {
                $prefixPlusSeperator = "$alternatePrefix$seperator"
                $this._PossibleCommandPrefixes.Add($prefixPlusSeperator) > $null
            }
        }
        $this.LogDebug('Configured command prefixes', $this._PossibleCommandPrefixes)
    }

    # Send the response to the backend to execute
    [void]SendMessage([Response]$Response) {
        $this.LogInfo('Sending response to backend')
        $this.Backend.SendMessage($Response)
    }

    # Get any parameters with the
    [hashtable]GetConfigProvidedParameters([PluginCommand]$PluginCmd) {
        if ($PluginCmd.Command.FunctionInfo) {
            $command = $PluginCmd.Command.FunctionInfo
        } else {
            $command = $PluginCmd.Command.CmdletInfo
        }
        $this.LogDebug("Inspecting command [$($PluginCmd.ToString())] for configuration-provided parameters")
        $configParams = foreach($param in $Command.Parameters.GetEnumerator() | Select-Object -ExpandProperty Value) {
            foreach ($attr in $param.Attributes) {
                if ($attr.GetType().ToString() -eq 'PoshBot.FromConfig') {
                    [ConfigProvidedParameter]::new($attr, $param)
                }
            }
        }

        $configProvidedParams = @{}
        if ($configParams) {
            $configParamNames = $configParams.Parameter | Select-Object -ExpandProperty Name
            $this.LogInfo("Command [$($PluginCmd.ToString())] has configuration provided parameters", $configParamNames)
            $pluginConfig = $this.Configuration.PluginConfiguration[$PluginCmd.Plugin.Name]
            if ($pluginConfig) {
                $this.LogDebug("Inspecting bot configuration for parameter values matching command [$($PluginCmd.ToString())]")
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
                if ($configProvidedParams.Count -ge 0) {
                    $this.LogDebug('Configuration supplied parameter values', $configProvidedParams)
                }
            } else {
                # No plugin configuration defined.
                # Unable to provide values for these parameters
                $this.LogDebug([LogSeverity]::Warning, "Command [$($PluginCmd.ToString())] has requested configuration supplied parameters but none where found")
            }
        } else {
            $this.LogDebug("Command [$($PluginCmd.ToString())] has 0 configuration provided parameters")
        }

        return $configProvidedParams
    }

    # Determine if response from command is custom and the output should be formatted
    hidden [bool]_IsCustomResponse([object]$Response) {
        $isCustom = (($Response.PSObject.TypeNames[0] -eq 'PoshBot.Text.Response') -or
                     ($Response.PSObject.TypeNames[0] -eq 'PoshBot.Card.Response') -or
                     ($Response.PSObject.TypeNames[0] -eq 'PoshBot.File.Upload') -or
                     ($Response.PSObject.TypeNames[0] -eq 'Deserialized.PoshBot.Text.Response') -or
                     ($Response.PSObject.TypeNames[0] -eq 'Deserialized.PoshBot.Card.Response') -or
                     ($Response.PSObject.TypeNames[0] -eq 'Deserialized.PoshBot.File.Upload'))

        if ($isCustom) {
            $this.LogDebug("Detected custom response [$($Response.PSObject.TypeNames[0])] from command")
        }

        return $isCustom
    }

    # Test if an object is a primitive data type
    hidden [bool] _IsPrimitiveType([object]$Item) {
        $primitives = @('Byte', 'SByte', 'Int16', 'Int32', 'Int64', 'UInt16', 'UInt32', 'UInt64',
                        'Decimal', 'Single', 'Double', 'TimeSpan', 'DateTime', 'ProgressRecord',
                        'Char', 'String', 'XmlDocument', 'SecureString', 'Boolean', 'Guid', 'Uri', 'Version'
        )
        return ($Item.GetType().Name -in $primitives)
    }
}
