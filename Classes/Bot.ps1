
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

    Bot([string]$Name, [Backend]$Backend, [string]$PoshBotDir, [string]$ConfigDir) {
        $this.Name = $Name
        $this.Backend = $Backend
        $this._PoshBotDir = $PoshBotDir
        $this.Storage = [StorageProvider]::new($ConfigDir)
        $this.Initialize()
    }

    [void]Initialize() {
        $this.LoadConfiguration()
        $this._Logger = [Logger]::new($this.Configuration.LogDirectory)
        $this.RoleManager = [RoleManager]::new($this.Backend, $this.Storage, $this._Logger)
        $this.PluginManager = [PluginManager]::new($this.RoleManager, $this.Storage, $this._Logger, $this._PoshBotDir)
        $this.Executor = [CommandExecutor]::new($this.RoleManager)
        $this.GenerateCommandPrefixList()
    }

    [void]LoadConfiguration() {
        $botConfig = $this.Storage.GetConfig('Bot')
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
        $this._Logger.Log([LogMessage]::new('[Bot:Start] Start your engines'), [LogType]::System)

        try {
            $this.Connect()

            # Start the loop to receive and process messages from the backend
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            $this._Logger.Log([LogMessage]::new('[Bot:Start] Beginning message processing loop'), [LogType]::System)
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
            $msg = [LogMessage]::new("[Bot:Start] Exception [$($_.Exception.Message)]", $errJson)
            $this._Logger.Log($msg, [LogType]::System)
            $this._Logger.Log($msg, [LogType]::Debug)
        } finally {
            $this.Disconnect()
        }
    }

    # Connect the bot to the chat network
    [void]Connect() {
        $this._Logger.Log([LogMessage]::new('[Bot:Connect] Connecting to backend chat network'), [LogType]::System)
        $this.Backend.Connect()
    }

    # Disconnect the bot from the chat network
    [void]Disconnect() {
        $this._Logger.Log([LogMessage]::new('[Bot:Disconnect] Disconnecting from backend chat network'), [LogType]::System)
        $this.Backend.Disconnect()
    }

    # Receive an event from the backend chat network
    [Message]ReceiveMessage() {
        $msg = $this.Backend.ReceiveMessage()
        # The backend MAY return a NULL message. Ignore it
        if ($msg) {
            # If the message is a bot command or another type of message we should care
            # about, add it to the message queue for processing
            if ($this.IsBotCommand($msg)) {
                $this._Logger.Log([LogMessage]::new('[Bot:ReceiveMessage] Received bot message from chat network. Adding to message queue.', $msg), [LogType]::System)
                $this._Logger.Log([LogMessage]::new('[Bot:Received message]', $msg), [LogType]::Receive)
                $this.MessageQueue.Enqueue($msg)
            } else {
                # TODO
                # Some other type of message we are watching for
            }
        }
        return $msg
    }

    [bool]IsBotCommand([Message]$Message) {
        $firstWord = ($Message.Text -split ' ')[0]
        foreach ($prefix in $this._PossibleCommandPrefixes ) {
            if ($firstWord -match "^$prefix") {
                $this._Logger.Log([LogMessage]::new('[Bot:IsBotCommand] Message is a bot command.'), [LogType]::System)
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
                $this._Logger.Log([LogMessage]::new('[Bot:ProcessMessageQueue] Dequeued message', $msg), [LogType]::System)
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

            $Message = $this.TrimPrefix($Message)
            $commandString = $Message.Text

            $parsedCommand = [CommandParser]::Parse($commandString)
            $this._Logger.Log([LogMessage]::new('[Bot:HandleMessage] Parsed bot command', $parsedCommand), [LogType]::System)

            $response = [Response]::new()
            $response.MessageFrom = $Message.From
            $response.To = $Message.To

            # Match parsed command to a command in the plugin manager
            $pluginCmd = $this.PluginManager.MatchCommand($parsedCommand)
            if ($pluginCmd) {

                # Pass in the bot to the module command.
                # We need this for builtin commands
                if ($pluginCmd.Plugin.Name -eq 'Builtin') {
                    $parsedCommand.NamedParameters.Add('Bot', $this)
                }

                $result = $this.DispatchCommand($pluginCmd.Command, $parsedCommand, $Message.From)
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
                                    New-PoshBotCardResponse -Type Error -Text $_.Message -Title 'Command Exception'
                                }
                            }
                        } else {
                            $response.Data = New-PoshBotCardResponse -Type Error -Text 'Something bad happened :(' -Title 'Command Error'
                        }
                    }
                } else {
                    foreach ($r in $result.Output) {
                        if (($r.PSObject.TypeNames[0] -eq 'PoshBot.Text.Response') -or ($r.PSObject.TypeNames[0] -eq 'PoshBot.Card.Response')) {
                            Write-Host "Received custom PoshBot response: [$($r.PSObject.TypeNames[0])]"
                            Write-host $r
                            $response.Data += $r
                        } else {
                            Write-Host "Received text response: [$($result.Output)]"
                            $response.Text += $($r | Format-List * | Out-String)
                        }
                    }
                    #$response.Text = $($result.Output | Format-List * | Out-String)
                }
                $this.SendMessage($response)
            } else {
                $msg = "No command found matching [$commandString]"
                $this._Logger.Log([LogMessage]::new($msg, $parsedCommand), [LogType]::System)
                # Only respond with command not found message if configuration allows it.
                if (-not $this.Configuration.MuteUnknownCommand) {
                    $response.Severity = [Severity]::Warning
                    $response.Data = New-PoshBotCardResponse -Type Warning -Text $msg
                    $this.SendMessage($response)
                }
            }
        }
    }

    # Dispatch the command to the executor
    [CommandResult]DispatchCommand([Command]$Command, [ParsedCommand]$ParsedCommand, [string]$CallerId) {
        $result = $this.Executor.ExecuteCommand($Command, $ParsedCommand, $CallerId)
        return $result
    }

    # Trim the command prefix or any alternate prefix or seperators off the message
    # as we won't need them anymore.
    [Message]TrimPrefix([Message]$Message) {
        $Message.Text = $Message.Text.Trim()
        $firstWord = ($Message.Text -split ' ')[0]

        foreach ($prefix in $this._PossibleCommandPrefixes) {
            if ($firstWord -match "^$prefix") {
                $Message.Text = $Message.Text.TrimStart($prefix).Trim()
                write-host $Message.Text
                #break
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

    [void]SendMessage([Card]$Response) {
        $this.Backend.SendMessage($Response)
    }
}

function New-PoshBotInstance {
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        [string]$Name,

        [Backend]$Backend,

        [string]$ConfigurationDirectory = (Join-Path -Path $env:USERPROFILE -ChildPath '.poshbot')
    )
    $here = $script:moduleRoot
    [Bot]::new($Name, $Backend, $here, $ConfigurationDirectory)
}

function Add-PoshBotPlugin {
    [cmdletbinding()]
    param(
        [parameter(Mandatory, ValueFromPipeline)]
        [Alias('Bot')]
        [Bot]$InputObject,

        [parameter(Mandatory)]
        [ValidateScript({Test-Path -Path $_})]
        [string]$ModuleManifest
    )
    Write-Verbose -Message "Creating bot plugin from module [$ModuleManifest]"
    $bot.PluginManager.InstallPlugin($ModuleManifest)
}
