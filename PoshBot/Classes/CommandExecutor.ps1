
# In charge of executing and tracking progress of commands
class CommandExecutor {

    [RoleManager]$RoleManager

    hidden [Bot]$_bot

    [int]$HistoryToKeep = 100

    [int]$ExecutedCount = 0

    # Recent history of commands executed
    [System.Collections.ArrayList]$History = (New-Object System.Collections.ArrayList)

    # Plugin commands get executed as PowerShell jobs
    # This is to keep track of those
    hidden [hashtable]$_jobTracker = @{}

    CommandExecutor([RoleManager]$RoleManager, [Bot]$Bot) {
        $this.RoleManager = $RoleManager
        $this._bot = $Bot
    }

    # Execute a command
    [void]ExecuteCommand([PluginCommand]$PluginCmd, [ParsedCommand]$ParsedCommand, [Message]$Message) {

        $cmdExecContext = [CommandExecutionContext]::new()
        $cmdExecContext.Started = (Get-Date).ToUniversalTime()
        $cmdExecContext.Result = [CommandResult]::New()
        $cmdExecContext.Command = $pluginCmd.Command
        $cmdExecContext.FullyQualifiedCommandName = $pluginCmd.ToString()
        $cmdExecContext.ParsedCommand = $ParsedCommand
        $cmdExecContext.Message = $Message

        # Verify command is not disabled
        if (-not $cmdExecContext.Command.Enabled) {
            $err = [CommandDisabled]::New("Command [$($cmdExecContext.Command.Name)] is disabled")
            $cmdExecContext.Complete = $true
            $cmdExecContext.Ended = (Get-Date).ToUniversalTime()
            $cmdExecContext.Result.Success = $false
            $cmdExecContext.Result.Errors += $err
            Write-Error -Exception $err
            $this.TrackJob($cmdExecContext)
            return
        }

        # Verify that all mandatory parameters have been provided for "command" type bot commands
        # This doesn't apply to commands triggered from regex matches, timers, or events
        if ([TriggerType]::Command -in $cmdExecContext.Command.Triggers.Type ) {
            if (-not $this.ValidateMandatoryParameters($ParsedCommand, $cmdExecContext.Command)) {
                $msg = "Mandatory parameters for [$($cmdExecContext.Command.Name)] not provided.`nUsage:`n"
                foreach ($usage in $cmdExecContext.Command.Usage) {
                    $msg += "    $usage`n"
                }
                $err = [CommandRequirementsNotMet]::New($msg)
                $cmdExecContext.Complete = $true
                $cmdExecContext.Ended = (Get-Date).ToUniversalTime()
                $cmdExecContext.Result.Success = $false
                $cmdExecContext.Result.Errors += $err
                Write-Error -Exception $err
                $this.TrackJob($cmdExecContext)
                return
            }
        }

        # If command is [command] type verify that the caller is authorized to execute it
        if ([TriggerType]::Command -in $cmdExecContext.Command.Triggers.Type ) {
            $authorized = $cmdExecContext.Command.IsAuthorized($Message.From, $this.RoleManager)
        } else {
            $authorized = $true
        }

        if ($authorized) {

            # Add reaction telling the user that the command is being executed
            $this._bot.Backend.AddReaction($Message, [ReactionType]::Processing)

            if ($cmdExecContext.Command.AsJob) {
                # Kick off job and add to job tracker
                $cmdExecContext.IsJob = $true
                $cmdExecContext.Job = $cmdExecContext.Command.Invoke($ParsedCommand, $true)
                $cmdExecContext.Complete = $false
            } else {
                # Run command in current session and get results
                # This should only be 'builtin' commands
                try {
                    $cmdExecContext.IsJob = $false
                    $hash = $cmdExecContext.Command.Invoke($ParsedCommand, $false)
                    $cmdExecContext.Complete = $true
                    $cmdExecContext.Ended = (Get-Date).ToUniversalTime()
                    $cmdExecContext.Result.Errors = $hash.Error
                    $cmdExecContext.Result.Streams.Error = $hash.Error
                    $cmdExecContext.Result.Streams.Information = $hash.Information
                    $cmdExecContext.Result.Streams.Warning = $hash.Warning
                    $cmdExecContext.Result.Output = $hash.Output
                    if ($cmdExecContext.Result.Errors.Count -gt 0) {
                        $cmdExecContext.Result.Success = $false
                    } else {
                        $cmdExecContext.Result.Success = $true
                    }
                } catch {
                    $cmdExecContext.Complete = $true
                    $cmdExecContext.Result.Success = $false
                    $cmdExecContext.Result.Errors = $_.Exception.Message
                    $cmdExecContext.Result.Streams.Error = $_.Exception.Message
                }
            }
        } else {
            $msg = "Command [$($cmdExecContext.Command.Name)] was not authorized for user [$($Message.From)]"
            $cmdExecContext.Complete = $true
            $cmdExecContext.Result.Errors += [CommandNotAuthorized]::New($msg)
            $cmdExecContext.Result.Success = $false
            $cmdExecContext.Result.Authorized = $false
            $this.TrackJob($cmdExecContext)
            return
        }

        $this.TrackJob($cmdExecContext)
    }

    # Add the command execution context to the job tracker
    # So the status and results of it can be checked later
    [void]TrackJob([CommandExecutionContext]$CommandContext) {
        if (-not $this._jobTracker.ContainsKey($CommandContext.Id)) {
            Write-Verbose -Message "[CommandExecutor:TrackJob] - Adding job [$($CommandContext.Id)] to tracker"
            $this._jobTracker.Add($CommandContext.Id, $CommandContext)
        }
    }

    # Receive any completed jobs from the job tracker
    [CommandExecutionContext[]]ReceiveJob() {
        $results = New-Object System.Collections.ArrayList

        if ($this._jobTracker.Count -ge 1) {
            $completedJobs = $this._jobTracker.GetEnumerator() |
                Where-Object {($_.Value.Complete -eq $true) -or
                              ($_.Value.IsJob -and (($_.Value.Job.State -eq 'Completed') -or ($_.Value.Job.State -eq 'Failed')))} |
                Select-Object -ExpandProperty Value

            foreach ($cmdExecContext in $completedJobs) {
                # If the command was executed in a PS job, get the output
                # Builtin commands are NOT executed as jobs so their output
                # was already recorded in the [Result] property in the ExecuteCommand() method
                if ($cmdExecContext.IsJob) {
                    if ($cmdExecContext.Job.State -eq 'Completed') {

                        Write-Verbose -Message "[CommandExecutor:ReceiveJob] Job [$($cmdExecContext.Id)] is complete"
                        $cmdExecContext.Complete = $true
                        $cmdExecContext.Ended = (Get-Date).ToUniversalTime()

                        # Capture all the streams
                        $cmdExecContext.Result.Errors = $cmdExecContext.Job.ChildJobs[0].Error.ReadAll()
                        $cmdExecContext.Result.Streams.Error = $cmdExecContext.Result.Errors
                        $cmdExecContext.Result.Streams.Information = $cmdExecContext.Job.ChildJobs[0].Information.ReadAll()
                        $cmdExecContext.Result.Streams.Verbose = $cmdExecContext.Job.ChildJobs[0].Verbose.ReadAll()
                        $cmdExecContext.Result.Streams.Warning = $cmdExecContext.Job.ChildJobs[0].Warning.ReadAll()
                        $cmdExecContext.Result.Output = $cmdExecContext.Job.ChildJobs[0].Output.ReadAll()

                        # Determine if job had any terminating errors
                        if ($cmdExecContext.Result.Streams.Error.Count -gt 0) {
                            $cmdExecContext.Result.Success = $false
                            $this._bot.Backend.AddReaction($cmdExecContext.Message, [ReactionType]::Failure)
                        } else {
                            $cmdExecContext.Result.Success = $true
                            $this._bot.Backend.AddReaction($cmdExecContext.Message, [ReactionType]::Success)
                        }

                        Write-Debug -Message "[CommandExecutor:ReceiveJob] Job results:`n$($cmdExecContext.Result | ConvertTo-Json)"

                        # Clean up the job
                        Remove-Job -Job $cmdExecContext.Job
                    } elseIf ($cmdExecContext.Job.State -eq 'Failed') {
                        $cmdExecContext.Complete = $true
                        $cmdExecContext.Result.Success = $false
                    }
                }

                Write-Verbose -Message "[CommandExecutor:ReceiveJob] Removing job [$($cmdExecContext.Id)] from tracker"
                $this._jobTracker.Remove($cmdExecContext.Id)

                # Remove the reaction specifying the command is in process
                $this._bot.Backend.RemoveReaction($cmdExecContext.Message, [ReactionType]::Processing)

                # Track number of commands executed
                if ($cmdExecContext.Result.Success) {
                    $this.ExecutedCount++
                }

                $cmdExecContext.Result.Duration = ($cmdExecContext.Ended - $cmdExecContext.Started)

                $results.Add($cmdExecContext) > $null
            }
        }

        return $results
    }

    # Add command result to history
    [void]AddToHistory([string]$CommandName, [string]$UserId, [CommandResult]$Result, [ParsedCommand]$ParsedCommand) {
        if ($this.History.Count -ge $this.HistoryToKeep) {
            $this.History.RemoveAt(0) > $null
        }
        $this.History.Add([CommandHistory]::New($CommandName, $UserId, $Result, $ParsedCommand))
    }

    # Validate that all mandatory parameters have been provided
    [bool]ValidateMandatoryParameters([ParsedCommand]$ParsedCommand, [Command]$Command) {
        $functionInfo = $Command.FunctionInfo

        $validated = $false
        foreach ($parameterSet in $functionInfo.ParameterSets) {
            Write-Verbose -Message "[CommandExecutor:ValidateMandatoryParameters] Validating parameters for parameter set [$($parameterSet.Name)]"
            $mandatoryParameters = @($parameterSet.Parameters | Where-Object {$_.IsMandatory -eq $true}).Name
            if ($mandatoryParameters.Count -gt 0) {
                # Remove each provided mandatory parameter from the list
                # so we can find any that will have to be coverd by positional parameters
                Write-Verbose -Message "[CommandExecutor:ValidateMandatoryParameters] Provided named parameters: $($ParsedCommand.NamedParameters.Keys | Format-List | Out-String)"
                foreach ($providedNamedParameter in $ParsedCommand.NamedParameters.Keys ) {
                    Write-Verbose -Message "[CommandExecutor:ValidateMandatoryParameters] Named parameter [$providedNamedParameter] provided"
                    $mandatoryParameters = @($mandatoryParameters | Where-Object {$_ -ne $providedNamedParameter})
                }
                if ($mandatoryParameters.Count -gt 0) {
                    if ($ParsedCommand.PositionalParameters.Count -lt $mandatoryParameters.Count) {
                        $validated = $false
                    } else {
                        $validated = $true
                    }
                } else {
                    $validated = $true
                }
            } else {
                $validated = $true
            }

            Write-Verbose -Message "[CommandExecutor:ValidateMandatoryParameters] Valid parameters for parameterset [$($parameterSet.Name)] - [$($validated.ToString())]"
            if ($validated) {
                break
            }
        }

        return $validated
    }
}
