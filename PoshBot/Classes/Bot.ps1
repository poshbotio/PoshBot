
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

    [hashtable]$DeferredCommandExecutionContexts = @{}

    [System.Collections.Queue]$ProcessedDeferredContextQueue = (New-Object System.Collections.Queue)

    [BotConfiguration]$Configuration

    hidden [System.Diagnostics.Stopwatch]$_Stopwatch

    hidden [System.Collections.Arraylist] $_PossibleCommandPrefixes = (New-Object System.Collections.ArrayList)

    hidden [MiddlewareConfiguration] $_Middleware

    hidden [bool]$LazyLoadComplete = $false

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

        # Register middleware hooks
        $this._Middleware = $Config.MiddlewareConfiguration

        # Ugly hack alert!
        # Store the ConfigurationDirectory property in a script level variable
        # so the command class as access to it.
        $script:ConfigurationDirectory = $this.Configuration.ConfigurationDirectory

        # Add internal plugin directory and user-defined plugin directory to PSModulePath
        if (-not [string]::IsNullOrEmpty($this.Configuration.PluginDirectory)) {
            $internalPluginDir = Join-Path -Path $this._PoshBotDir -ChildPath 'Plugins'
            $modulePaths = $env:PSModulePath.Split($script:pathSeperator)
            if ($modulePaths -notcontains $internalPluginDir) {
                $env:PSModulePath = $internalPluginDir + $script:pathSeperator + $env:PSModulePath
            }
            if ($modulePaths -notcontains $this.Configuration.PluginDirectory) {
                $env:PSModulePath = $this.Configuration.PluginDirectory + $script:pathSeperator + $env:PSModulePath
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
        $OldFormatEnumerationLimit = $global:FormatEnumerationLimit
        if($this.Configuration.FormatEnumerationLimitOverride -is [int]) {
            $global:FormatEnumerationLimit = $this.Configuration.FormatEnumerationLimitOverride
            $this.LogInfo("Setting global FormatEnumerationLimit to [$($this.Configuration.FormatEnumerationLimitOverride)]")
        }
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

                # Determine if any contexts that are deferred are expired
                $this.ProcessDeferredContexts()

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
            $global:FormatEnumerationLimit = $OldFormatEnumerationLimit
            $this.Disconnect()
        }
    }

    # Connect the bot to the chat network
    [void]Connect() {
        $this.LogVerbose('Connecting to backend chat network')
        $this.Backend.Connect()

        # If the backend is not configured to lazy load
        # then add admins now
        if (-not $this.Backend.LazyLoadUsers) {
            $this._LoadAdmins()
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

            # If the backend lazy loads and has done so
            if (($this.Backend.LazyLoadUsers) -and (-not $this.LazyLoadComplete)) {
                $this._LoadAdmins()
                $this.LazyLoadComplete = $true
            }

            # Ignore DMs if told to
            if ($msg.IsDM -and $this.Configuration.DisallowDMs) {
                $this.LogInfo('Ignoring message. DMs are disabled.', $msg)
                $this.AddReaction($msg, [ReactionType]::Denied)
                $response = [Response]::new($msg)
                $response.Severity = [Severity]::Warning
                $response.Data = New-PoshBotCardResponse -Type Warning -Text 'Sorry :( PoshBot has been configured to ignore DMs (direct messages). Please contact your bot administrator.'
                $this.SendMessage($response)
                return
            }

            # HTML decode message text
            # This will ensure characters like '&' that MAY have
            # been encoded as &amp; on their way in get translated
            # back to the original
            if (-not [string]::IsNullOrEmpty($msg.Text)) {
                $msg.Text = [System.Net.WebUtility]::HtmlDecode($msg.Text)
            }

            # Execute PreReceive middleware hooks
            $cmdExecContext = [CommandExecutionContext]::new()
            $cmdExecContext.Started = (Get-Date).ToUniversalTime()
            $cmdExecContext.Message = $msg
            $cmdExecContext = $this._ExecuteMiddleware($cmdExecContext, [MiddlewareType]::PreReceive)

            if ($cmdExecContext) {
                $this.LogDebug('Received bot message from chat network. Adding to message queue.', $cmdExecContext.Message)
                $this.MessageQueue.Enqueue($cmdExecContext.Message)
            }
        }
    }

    # Receive any messages from the scheduler that had their timer elapse and should be executed
    [void]ProcessScheduledMessages() {
        foreach ($msg in $this.Scheduler.GetTriggeredMessages()) {
            $this.LogDebug('Received scheduled message from scheduler. Adding to message queue.', $msg)
            $this.MessageQueue.Enqueue($msg)
        }
    }

    [void]ProcessDeferredContexts() {
        $now = (Get-Date).ToUniversalTime()
        $expireMinutes = $this.Configuration.ApprovalConfiguration.ExpireMinutes

        $toRemove = New-Object System.Collections.ArrayList
        foreach ($context in $this.DeferredCommandExecutionContexts.Values) {
            $expireTime = $context.Started.AddMinutes($expireMinutes)
            if ($now -gt $expireTime) {
                $msg = "[$($context.Id)] - [$($context.ParsedCommand.CommandString)] has been pending approval for more than [$expireMinutes] minutes. The command will be cancelled."

                # Add cancelled reation
                $this.RemoveReaction($context.Message, [ReactionType]::ApprovalNeeded)
                $this.AddReaction($context.Message, [ReactionType]::Cancelled)

                # Send message back to backend saying command context was cancelled due to timeout
                $this.LogInfo($msg)
                $response = [Response]::new($context.Message)
                $response.Data = New-PoshBotCardResponse -Type Warning -Text $msg
                $this.SendMessage($response)

                $toRemove.Add($context.Id)
            }
        }
        foreach ($id in $toRemove) {
            $this.DeferredCommandExecutionContexts.Remove($id)
        }

        while ($this.ProcessedDeferredContextQueue.Count -ne 0) {
            $cmdExecContext = $this.ProcessedDeferredContextQueue.Dequeue()
            $this.DeferredCommandExecutionContexts.Remove($cmdExecContext.Id)

            if ($cmdExecContext.ApprovalState -eq [ApprovalState]::Approved) {
                $this.LogDebug("Starting exeuction of context [$($cmdExecContext.Id)]")
                $this.RemoveReaction($cmdExecContext.Message, [ReactionType]::ApprovalNeeded)
                $this.Executor.ExecuteCommand($cmdExecContext)
            } elseif ($cmdExecContext.ApprovalState -eq [ApprovalState]::Denied) {
                $this.LogDebug("Context [$($cmdExecContext.Id)] was denied")
                $this.RemoveReaction($cmdExecContext.Message, [ReactionType]::ApprovalNeeded)
                $this.AddReaction($cmdExecContext.Message, [ReactionType]::Denied)
            }
        }
    }

    # Determine if message text is addressing the bot and should be
    # treated as a bot command
     [bool]IsBotCommand([Message]$Message) {
        $firstWord = ($Message.Text -split ' ')[0].Trim()
        foreach ($prefix in $this._PossibleCommandPrefixes ) {
            $prefix = [regex]::Escape($prefix)
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

        #LUISMODIFICATION : CHECK IF THE BOT NAME OR ID IS IN THE MESSAGE
        $HandleThisMessage = $false

        if ($Message.To -eq $this.Configuration.BotID) {
            $HandleThisMessage = $true
        }
        else {
            foreach ($BotName in $this.Configuration.AlternateCommandPrefixes) {
                if ($Message.Text -like "*$($BotName)*") {
                    #Handle the message if it targets Arlette
                    $HandleThisMessage = $true
                }
            }
        }

        $cmdSearch = $true
        if (-not $isBotCommand) {
            $cmdSearch = $false
            $this.LogDebug('Message is not a bot command. Command triggers WILL NOT be searched.')
        } else {
            # The message is intended to be a bot command
            $Message = $this.TrimPrefix($Message)
        }

        #LUISMODIFICATION : PARSE MESSAGE WITH ALTERNATECOMMANDPREFIXES
        $parsedCommand = [CommandParser]::Parse($Message, $this.Configuration.AlternateCommandPrefixes)
        $this.LogDebug('Parsed bot command', $parsedCommand)

        # Attempt to populate the parsed command with full user info from the backend
        $parsedCommand.CallingUserInfo = $this.Backend.GetUserInfo($parsedCommand.From)

         # Match parsed command to a command in the plugin manager
        $pluginCmd = $this.PluginManager.MatchCommand($parsedCommand, $cmdSearch)

        #LUISMODIFICATION : use the default LUIS command if the bot is mentionned above, recharge $plugincmd

        if ($HandleThisMessage) {
            if (!$pluginCmd ) {
                $parsedCommand.Command = $this.Configuration.LuisCommand
                            [string[]]$NewParamArray = "$($parsedCommand.CommandString)"
                $parsedCommand.PositionalParameters = $NewParamArray
                $cmdSearch = $true
            }

            $pluginCmd = $this.PluginManager.MatchCommand($parsedCommand, $cmdSearch)
        }

       
        if ($pluginCmd) {

            # Create the command execution context
            $cmdExecContext = [CommandExecutionContext]::new()
            $cmdExecContext.Started = (Get-Date).ToUniversalTime()
            $cmdExecContext.Result = [CommandResult]::New()
            $cmdExecContext.Command = $pluginCmd.Command
            $cmdExecContext.FullyQualifiedCommandName = $pluginCmd.ToString()
            $cmdExecContext.ParsedCommand = $parsedCommand
            $cmdExecContext.Message = $Message

            # Execute PostReceive middleware hooks
            $cmdExecContext = $this._ExecuteMiddleware($cmdExecContext, [MiddlewareType]::PostReceive)

            if ($cmdExecContext) {
                # Check command is allowed in channel
                if (-not $this.CommandInAllowedChannel($parsedCommand, $pluginCmd)) {
                    $this.LogDebug('Igoring message. Command not approved in channel', $pluginCmd.ToString())
                    $this.AddReaction($Message, [ReactionType]::Denied)
                    $response = [Response]::new($Message)
                    $response.Severity = [Severity]::Warning
                    $response.Data = New-PoshBotCardResponse -Type Warning -Text 'Sorry :( PoshBot has been configured to not allow that command in this channel. Please contact your bot administrator.'
                    $this.SendMessage($response)
                    return
                }

                # Add the name of the plugin to the parsed command
                # if it wasn't fully qualified to begin with
                if ([string]::IsNullOrEmpty($parsedCommand.Plugin)) {
                    $parsedCommand.Plugin = $pluginCmd.Plugin.Name
                }

                # If the command trigger is a [regex], then we shoudn't parse named/positional
                # parameters from the message so clear them out. Only the regex matches and
                # config provided parameters are allowed.
                if ([TriggerType]::Regex -in $pluginCmd.Command.Triggers.Type) {
                    $parsedCommand.NamedParameters = @{}
                    $parsedCommand.PositionalParameters = @()
                    $regex = [regex]$pluginCmd.Command.Triggers[0].Trigger
                    $parsedCommand.NamedParameters['Arguments'] = $regex.Match($parsedCommand.CommandString).Groups | Select-Object -ExpandProperty Value
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
                        $this.LogDebug("Inserting configuration provided named parameter", $cp)
                        $parsedCommand.NamedParameters.Add($cp.Name, $cp.Value)
                    }
                }

                # Execute PreExecute middleware hooks
                $cmdExecContext = $this._ExecuteMiddleware($cmdExecContext, [MiddlewareType]::PreExecute)

                if ($cmdExecContext) {
                    $this.Executor.ExecuteCommand($cmdExecContext)
                }
            }
        } else {
            if ($isBotCommand) {
                $msg = "No command found matching [$($Message.Text)]"
                $this.LogInfo([LogSeverity]::Warning, $msg, $parsedCommand)
                # Only respond with command not found message if configuration allows it.
                if (-not $this.Configuration.MuteUnknownCommand) {
                    $response = [Response]::new($Message)
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

            # Execute PostExecute middleware hooks
            $cmdExecContext = $this._ExecuteMiddleware($cmdExecContext, [MiddlewareType]::PostExecute)

            if ($cmdExecContext) {
                $cmdExecContext.Response = [Response]::new($cmdExecContext.Message)

                if (-not $cmdExecContext.Result.Success) {
                    # Was the command authorized?
                    if (-not $cmdExecContext.Result.Authorized) {
                        $cmdExecContext.Response.Severity = [Severity]::Warning
                        $cmdExecContext.Response.Data = New-PoshBotCardResponse -Type Warning -Text "You do not have authorization to run command [$($cmdExecContext.Command.Name)] :(" -Title 'Command Unauthorized'
                        $this.LogInfo([LogSeverity]::Warning, 'Command unauthorized')
                    } else {
                        $cmdExecContext.Response.Severity = [Severity]::Error
                        if ($cmdExecContext.Result.Errors.Count -gt 0) {
                            $cmdExecContext.Response.Data = $cmdExecContext.Result.Errors | ForEach-Object {
                                if ($_.Exception) {
                                    New-PoshBotCardResponse -Type Error -Text $_.Exception.Message -Title 'Command Exception'
                                } else {
                                    New-PoshBotCardResponse -Type Error -Text $_ -Title 'Command Exception'
                                }
                            }
                        } else {
                            $cmdExecContext.Response.Data += New-PoshBotCardResponse -Type Error -Text 'Something bad happened :(' -Title 'Command Error'
                            $cmdExecContext.Response.Data += $cmdExecContext.Result.Errors
                        }
                        $this.LogInfo([LogSeverity]::Error, "Errors encountered running command [$($cmdExecContext.FullyQualifiedCommandName)]", $cmdExecContext.Result.Errors)
                    }
                } else {
                    $this.LogVerbose('Command execution result', $cmdExecContext.Result)
                    foreach ($resultOutput in $cmdExecContext.Result.Output) {
                        if ($null -ne $resultOutput) {
                            if ($this._IsCustomResponse($resultOutput)) {
                                $cmdExecContext.Response.Data += $resultOutput
                            } else {
                                # If the response is a simple type, just display it as a string
                                # otherwise we need remove auto-generated properties that show up
                                # from deserialized objects
                                if ($this._IsPrimitiveType($resultOutput)) {
                                    $cmdExecContext.Response.Text += $resultOutput.ToString().Trim()
                                } else {
                                    $deserializedProps = 'PSComputerName', 'PSShowComputerName', 'PSSourceJobInstanceId', 'RunspaceId'
                                    $resultText = $resultOutput | Select-Object -Property * -ExcludeProperty $deserializedProps
                                    $cmdExecContext.Response.Text += ($resultText | Format-List -Property * | Out-String).Trim()
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
                foreach ($rule in $this.Configuration.SendCommandResponseToPrivate) {
                    if ($cmdExecContext.FullyQualifiedCommandName -like $rule) {
                        $this.LogInfo("Deverting response from command [$($cmdExecContext.FullyQualifiedCommandName)] to private channel")
                        $cmdExecContext.Response.To = "@$($this.RoleManager.ResolveUserIdToUserName($cmdExecContext.Message.From))"
                        break
                    }
                }

                # Execute PreResponse middleware hooks
                $cmdExecContext = $this._ExecuteMiddleware($cmdExecContext, [MiddlewareType]::PreResponse)

                # Send response back to chat network
                if ($cmdExecContext) {
                    $this.SendMessage($cmdExecContext.Response)
                }

                # Execute PostResponse middleware hooks
                $cmdExecContext = $this._ExecuteMiddleware($cmdExecContext, [MiddlewareType]::PostResponse)
            }

            $this.LogInfo("Done processing command [$($cmdExecContext.FullyQualifiedCommandName)]")
        }
    }

    # Trim the command prefix or any alternate prefix or seperators off the message
    # as we won't need them anymore.
    [Message]TrimPrefix([Message]$Message) {
        if (-not [string]::IsNullOrEmpty($Message.Text)) {
            $firstWord = ($Message.Text -split ' ')[0].Trim()
            foreach ($prefix in $this._PossibleCommandPrefixes) {
                $prefixEscaped = [regex]::Escape($prefix)
                if ($firstWord -match "^$prefixEscaped") {
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

    # Add a reaction to a message
    [void]AddReaction([Message]$Message, [ReactionType]$ReactionType) {
        if ($this.Configuration.AddCommandReactions) {
            $this.Backend.AddReaction($Message, $ReactionType)
        }
    }

    # Remove a reaction from a message
    [void]RemoveReaction([Message]$Message, [ReactionType]$ReactionType) {
        if ($this.Configuration.AddCommandReactions) {
            $this.Backend.RemoveReaction($Message, $ReactionType)
        }
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

    # Check command against approved commands in channels
    [bool]CommandInAllowedChannel([ParsedCommand]$ParsedCommand, [PluginCommand]$PluginCommand) {

        # DMs won't be governed by the 'ApprovedCommandsInChannel' configuration property
        if ($ParsedCommand.OriginalMessage.IsDM) {
            return $true
        }

        $channel = $ParsedCommand.ToName
        $fullyQualifiedCommand = $PluginCommand.ToString()

        # Match command against included/excluded commands for the channel
        # If there is a channel match, assume command is NOT approved unless
        # it matches the included commands list and DOESN'T match the excluded list
        foreach ($ChannelRule in $this.Configuration.ChannelRules) {
            if ($channel -like $ChannelRule.Channel) {
                foreach ($includedCommand in $ChannelRule.IncludeCommands) {
                    if ($fullyQualifiedCommand -like $includedCommand) {
                        $this.LogDebug("Matched [$fullyQualifiedCommand] to included command [$includedCommand]")
                        foreach ($excludedCommand in $ChannelRule.ExcludeCommands) {
                            if ($fullyQualifiedCommand -like $excludedCommand) {
                                $this.LogDebug("Matched [$fullyQualifiedCommand] to excluded command [$excludedCommand]")
                                return $false
                            }
                        }

                        return $true
                    }
                }
                return $false
            }
        }

        return $false
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

    hidden [CommandExecutionContext] _ExecuteMiddleware([CommandExecutionContext]$Context, [MiddlewareType]$Type) {

        $hooks = $this._Middleware."$($Type.ToString())Hooks"

        # Execute PostResponse middleware hooks
        foreach ($hook in $hooks.Values) {
            try {
                $this.LogDebug("Executing [$($Type.ToString())] hook [$($hook.Name)]")
                if ($null -ne $Context) {
                    $Context = $hook.Execute($Context, $this)
                    if ($null -eq $Context) {
                        $this.LogInfo([LogSeverity]::Warning, "[$($Type.ToString())] middleware [$($hook.Name)] dropped message.")
                        break
                    }
                }
            } catch {
                $this.LogInfo([LogSeverity]::Error, "[$($Type.ToString())] middleware [$($hook.Name)] raised an exception. Command context dropped.", [ExceptionFormatter]::Summarize($_))
                return $null
            }
        }

        return $Context
    }

    # Resolve any bot administrators defined in configuration to their IDs
    # and add to the [admin] role
    hidden [void] _LoadAdmins() {
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
}
