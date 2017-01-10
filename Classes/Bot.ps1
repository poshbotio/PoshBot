
class Bot {

    # Friendly name for the bot
    [string]$Name

    # The backend system for this bot (Slack, HipChat, etc)
    [Backend]$Backend

    hidden [string]$_PoshBotDir

    # List of commands available from plugins
    [hashtable]$Commands = @{}

    # List of roles loaded from plugins
    [hashtable]$Roles = @{}

    [StorageProvider]$Storage

    [PluginManager]$PluginManager

    [RoleManager]$RoleManager

    [CommandExecutor]$Executor

    # Queue of messages from the chat network to process
    [System.Collections.Queue]$MessageQueue = (New-Object System.Collections.Queue)

    [string]$CommandPrefix = '!'

    hidden [bool]$_ShouldRun = $true

    hidden [Logger]$_Logger

    hidden [System.Diagnostics.Stopwatch]$_Stopwatch

    Bot([string]$Name, [Backend]$Backend, [string]$PoshBotDir) {
        $this.Name = $Name
        $this.Backend = $Backend
        #$this.AttachBackend($Backend)
        $this._PoshBotDir = $PoshBotDir
        $this._Logger = [Logger]::new()
        $this.Initialize()
    }

    Bot([string]$Name, [Backend]$Backend, [string]$PoshBotDir, [string]$LogPath) {
        $this.Name = $Name
        $this.Backend = $Backend
        #$this.AttachBackend($Backend)
        $this._PoshBotDir = $PoshBotDir
        $this._Logger = [Logger]::new($LogPath)
        $this.Initialize()
    }

    [void]Initialize() {
        # TODO
        # Load in configuration from persistent storage

        $this.Storage = [StorageProvider]::new()
        $this.RoleManager = [RoleManager]::new($this.Backend, $this.Storage, $this._Logger)
        $this.PluginManager = [PluginManager]::new($this.RoleManager, $this._Logger, $this._PoshBotDir)
        $this.Executor = [CommandExecutor]::new($this.RoleManager)
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
            while ($this._ShouldRun -and $this.Backend.Connection.Connected) {

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

    # # Attach the backend (chat network specific) implementation
    # [void]AttachBackend([Backend]$Backend) {
    #     $this._Logger.Log([LogMessage]::new('[Bot:AttachBackend] Attaching backend'), [LogType]::System)
    #     $this.Backend = $Backend
    # }

    # Receive an event from the backend chat network
    [Message]ReceiveMessage() {
        $msg = $this.Backend.ReceiveMessage()
        # The backend MAY return a NULL message. Ignore it
        if ($msg) {
            # If the message is a bot command or another type of message we should care
            # about, add it to the message queue for processing
            #if ($this.IsBotCommand($msg)) {
                $this._Logger.Log([LogMessage]::new('[Bot:ReceiveMessage] Received bot message from chat network. Adding to message queue.', $msg), [LogType]::System)
                $this._Logger.Log([LogMessage]::new('[Bot:Received message]', $msg), [LogType]::Receive)
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
    #         $this._Logger.Log([LogMessage]::new('[Bot:IsBotCommand] Message is a bot command.'), [LogType]::System)
    #     } else {

    #         # foreach ($trigger in $this.Triggers.Keys) {
    #         #     if ($Message.Text -Match $trigger) {
    #         #         $match = $true
    #         #         $this._Logger.Log([LogMessage]::new("[Bot:IsBotCommand] Message matches trigger [$trigger]."), [LogType]::System)
    #         #         break
    #         #     }
    #         # }
    #     }

    #     return $match
    # }

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
            $commandString = $Message.Text.TrimStart($this.CommandPrefix)
            $parsedCommand = [CommandParser]::Parse($commandString)
            $this._Logger.Log([LogMessage]::new('[Bot:HandleMessage] Parsed bot command', $parsedCommand), [LogType]::System)

            $response = [Response]::new()
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
                        $response.Text = "You do not have authorization to run command [$($pluginCmd.Command.Name)] :("
                    } else {
                        # TODO
                        # Handle this better
                        $response.Severity = [Severity]::Error
                        $response.Text = '[Bot:HandleMessage] Something bad happened :('
                    }
                } else {
                    $response.Text = $($result.Output | Format-List * | Out-String)
                }
                $this.SendMessage($response)
            } else {
                $response.Severity = [Severity]::Warning
                $response.Text = "No command found matching [$commandString]"
                $this.SendMessage($response)
            }
        }
    }

    # Dispatch the command to the plugin for execution
    [CommandResult]DispatchCommand([Command]$Command, [ParsedCommand]$ParsedCommand, [string]$CallerId) {

        $result = $this.Executor.ExecuteCommand($Command, $ParsedCommand, $CallerId)
        return $result

        # $logMsg = [LogMessage]::new("[Bot:DispatchCommand] Dispatching command [$($Command.Name)] to plugin [$($Plugin.Name)] with caller ID [$CallerId]")
        # $this._Logger.Log($logMsg, [LogType]::System)
        # $this._Logger.Log($logMsg, [LogType]::Command)
        # $result = $Plugin.InvokeCommand($Command, $ParsedCommand, $CallerId)
        # Write-Verbose "[Bot:DispatchCommand] Command result: $($result | Format-List * | Out-String)"
        # $logMsg = [LogMessage]::new('[Bot:DispatchCommand] Command result', $result)
        # $this._Logger.Log($logMsg, [LogType]::System)
        # $this._Logger.Log($logMsg, [LogType]::Command)
        # return $result

        # Determine how to respond back to the chat network now that
        # the command has completed. This is up to the command
        # TODO
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
}

function New-PoshBotInstance {
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        [string]$Name,

        [Backend]$Backend
    )
    $here = $script:moduleRoot
    $bot = [Bot]::new($Name, $Backend, $here)
    #$bot._PoshBotDir = $script:moduleRoot

    # if ($Backend) {
    #     $bot.AttachBackend($Backend)
    # }
    #$bot.Initialize()

    return $bot
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
