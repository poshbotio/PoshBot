
# In charge of executing and tracking progress of commands
class CommandExecutor : BaseLogger {

    [RoleManager]$RoleManager

    hidden [Bot]$_bot

    [int]$HistoryToKeep = 100

    [int]$ExecutedCount = 0

    # Recent history of commands executed
    [Collections.Generic.List[CommandExecutionContext]]$History = [Collections.Generic.List[CommandExecutionContext]]::new()

    # Plugin commands get executed as PowerShell jobs
    # This is to keep track of those
    hidden [hashtable]$_jobTracker = @{}

    CommandExecutor([RoleManager]$RoleManager, [Logger]$Logger, [Bot]$Bot) {
        $this.RoleManager = $RoleManager
        $this.Logger      = $Logger
        $this._bot        = $Bot
    }

    # Execute a command
    [void]ExecuteCommand([CommandExecutionContext]$Context) {

        # Verify command is not disabled
        if (-not $Context.Command.Enabled) {
            $err = [CommandDisabled]::New("Command [$($Context.Command.Name)] is disabled")
            $Context.Complete       = $true
            $Context.Ended          = [datetime]::UtcNow
            $Context.Result.Success = $false
            $Context.Result.Errors += $err
            $this.LogInfo([LogSeverity]::Error, $err.Message, $err)
            $this.TrackJob($Context)
            return
        }

        # Verify that all mandatory parameters have been provided for "command" type bot commands
        # This doesn't apply to commands triggered from regex matches, timers, or events
        if ($Context.Command.TriggerType -eq [TriggerType]::Command) {
            if (-not $this.ValidateMandatoryParameters($Context)) {
                $msg = "Mandatory parameters for [$($Context.Command.Name)] not provided.`nUsage:`n"
                foreach ($usage in $Context.Command.Usage) {
                    $msg += "    $usage`n"
                }
                $err = [CommandRequirementsNotMet]::New($msg)
                $Context.Complete       = $true
                $Context.Ended          = [datetime]::UtcNow
                $Context.Result.Success = $false
                $Context.Result.Errors += $err
                $this.LogInfo([LogSeverity]::Error, $err.Message, $err)
                $this.TrackJob($Context)
                return
            }
        }

        # If command is [command] or [regex] trigger types, verify that the caller is authorized to execute it
        if ($Context.Command.TriggerType -in @('Command', 'Regex')) {
            $authorized = $Context.Command.IsAuthorized($Context.Message.From, $this.RoleManager)
        } else {
            $authorized = $true
        }

        if ($authorized) {

            # Check if approval(s) are needed to execute this command
            if ($this.ApprovalNeeded($Context)) {
                $Context.ApprovalState = [ApprovalState]::Pending
                $this._bot.Backend.AddReaction($Context.Message, [ReactionType]::ApprovalNeeded)

                # Put this message in the deferred bucket until it is released by the [!approve] command from an authorized approver
                if (-not $this._bot.DeferredCommandExecutionContexts.ContainsKey($Context.id)) {
                    $this._bot.DeferredCommandExecutionContexts.Add($Context.id, $Context)
                } else {
                    $this.LogInfo([LogSeverity]::Error, "This shouldn't happen, but command execution context [$($Context.id)] is already in the deferred bucket")
                }

                $approverGroups = $this.GetApprovalGroups($Context) -join ', '
                $prefix = $this._bot.Configuration.CommandPrefix
                $msg = "Approval is needed to run [$($Context.ParsedCommand.CommandString)] from someone in the approval group(s) [$approverGroups]."
                $msg += "`nTo approve, say '$($prefix)approve $($Context.Id)'."
                $msg += "`nTo deny, say '$($prefix)deny $($Context.Id)'."
                $msg += "`nTo list pending approvals, say '$($prefix)pending'."
                $response = [Response]::new($Context.Message)
                $response.Data = New-PoshBotCardResponse -Type Warning -Title "Approval Needed for [$($Context.ParsedCommand.CommandString)]" -Text $msg
                $this._bot.SendMessage($response)
                return
            } else {

                # If command is [command] or [regex] trigger type, add reaction telling the user that the command is being executed
                # Reactions don't make sense for event triggered commands
                if ($Context.Command.TriggerType -in @('Command', 'Regex')) {
                    if ($this._bot.Configuration.AddCommandReactions) {
                        $this._bot.Backend.AddReaction($Context.Message, [ReactionType]::Processing)
                    }
                }

                if ($Context.Command.AsJob) {
                    $this.LogDebug("Command [$($Context.FullyQualifiedCommandName)] will be executed as a job")

                    # Kick off job and add to job tracker
                    $Context.IsJob = $true
                    $Context.Job = $Context.Command.Invoke($Context.ParsedCommand, $true,$this._bot.Backend.GetType().Name)
                    $this.LogDebug("Command [$($Context.FullyQualifiedCommandName)] executing in job [$($Context.Job.Id)]")
                    $Context.Complete = $false
                } else {
                    # Run command in current session and get results
                    # This should only be 'builtin' commands
                    try {
                        $Context.IsJob    = $false
                        $Context.Complete = $true
                        $Context.Ended    = [datetime]::UtcNow

                        $cmdResult                          = $Context.Command.Invoke($Context.ParsedCommand, $false,$this._bot.Backend.GetType().Name)
                        $Context.Result.Errors              = $cmdResult.Error
                        $Context.Result.Streams.Error       = $cmdResult.Error
                        $Context.Result.Streams.Information = $cmdResult.Information
                        $Context.Result.Streams.Warning     = $cmdResult.Warning
                        $Context.Result.Output              = $cmdResult.Output
                        if ($Context.Result.Errors.Count -gt 0) {
                            $Context.Result.Success = $false
                        } else {
                            $Context.Result.Success = $true
                        }
                        $this.LogVerbose("Command [$($Context.FullyQualifiedCommandName)] completed with successful result [$($Context.Result.Success)]")
                    } catch {
                        $Context.Complete             = $true
                        $Context.Result.Success       = $false
                        $Context.Result.Errors        = $_.Exception.Message
                        $Context.Result.Streams.Error = $_.Exception.Message
                        $this.LogInfo([LogSeverity]::Error, $_.Exception.Message, $_)
                    }
                }
            }
        } else {
            $msg = "Command [$($Context.Command.Name)] was not authorized for user [$($Context.Message.From)]"
            $err = [CommandNotAuthorized]::New($msg)
            $Context.Complete          = $true
            $Context.Result.Errors    += $err
            $Context.Result.Success    = $false
            $Context.Result.Authorized = $false
            $this.LogInfo([LogSeverity]::Error, $err.Message, $err)
            $this.TrackJob($Context)
            return
        }

        $this.TrackJob($Context)
    }

    # Add the command execution context to the job tracker
    # So the status and results of it can be checked later
    [void]TrackJob([CommandExecutionContext]$Context) {
        if (-not $this._jobTracker.ContainsKey($Context.Id)) {
            $this.LogVerbose("Adding job [$($Context.Id)] to tracker")
            $this._jobTracker.Add($Context.Id, $Context)
        }
    }

    # Receive any completed jobs from the job tracker
    [System.Collections.Generic.List[CommandExecutionContext]]ReceiveJob() {

        $results = [System.Collections.Generic.List[CommandExecutionContext]]::new()

        foreach ($context in $this._GetCompletedContexts()) {
            # If the command was executed in a PS job, get the output
            # Builtin commands are NOT executed as jobs so their output
            # was already recorded in the [Result] property in the ExecuteCommand() method
            if ($context.IsJob) {

                # Determine if job had any terminating errors and capture error stream
                if ($context.Job.State -in @('Completed', 'Failed')) {
                    $context.Result.Errors  = $context.Job.ChildJobs[0].Error.ReadAll()
                    $context.Result.Success = ($context.Result.Errors.Count -eq 0)
                }
                $this.LogVerbose("Command [$($context.FullyQualifiedCommandName)] with job ID [$($context.Id)] completed with result: [$($context.Result.Success)]")

                $context.Complete = $true
                $context.Ended = [datetime]::UtcNow

                # Capture all the streams
                $context.Result.Streams.Error       = $context.Result.Errors
                $context.Result.Streams.Information = $context.Job.ChildJobs[0].Information.ReadAll()
                $context.Result.Streams.Verbose     = $context.Job.ChildJobs[0].Verbose.ReadAll()
                $context.Result.Streams.Warning     = $context.Job.ChildJobs[0].Warning.ReadAll()
                $context.Result.Output              = $context.Job.ChildJobs[0].Output.ReadAll()

                # Clean up the job
                Remove-Job -Job $context.Job
            }

            # Send a success, warning, or fail reaction
            if ($context.Command.TriggerType -in @('Command', 'Regex')) {
                if ($this._bot.Configuration.AddCommandReactions) {
                    if (-not $context.Result.Success) {
                        $reaction = [ReactionType]::Failure
                    } elseIf ($context.Result.Streams.Warning.Count -gt 0) {
                        $reaction = [ReactionType]::Warning
                    } else {
                        $reaction = [ReactionType]::Success
                    }
                    $this._bot.Backend.AddReaction($context.Message, $reaction)
                }
            }

            # Add to history
            if ($context.Command.KeepHistory) {
                $this.AddToHistory($context)
            }

            $this.LogVerbose("Removing job [$($context.Id)] from tracker")
            $this._jobTracker.Remove($context.Id)

            # Remove the reaction specifying the command is in process
            if ($context.Command.TriggerType -in @('Command', 'Regex')) {
                if ($this._bot.Configuration.AddCommandReactions) {
                    $this._bot.Backend.RemoveReaction($context.Message, [ReactionType]::Processing)
                }
            }

            # Track number of commands executed
            if ($context.Result.Success) {
                $this.ExecutedCount++
            }

            $context.Result.Duration = ($context.Ended - $context.Started)

            $results.Add($context)
        }

        return $results
    }

    # Add command result to history
    [void]AddToHistory([CommandExecutionContext]$Context) {
        if ($this.History.Count -ge $this.HistoryToKeep) {
            $this.History.RemoveAt(0)
        }
        $this.LogDebug("Adding command execution [$($Context.Id)] to history")
        $this.History.Add($Context)
    }

    # Validate that all mandatory parameters have been provided
    [bool]ValidateMandatoryParameters([CommandExecutionContext]$Context) {

        $parsedCommand = $Context.ParsedCommand
        $command       = $Context.Command
        $validated     = $false

        if ($command.FunctionInfo) {
            $parameterSets = $command.FunctionInfo.ParameterSets
        } else {
            $parameterSets = $command.CmdletInfo.ParameterSets
        }

        foreach ($parameterSet in $parameterSets) {
            $this.LogDebug("Validating parameters for parameter set [$($parameterSet.Name)]")
            $mandatoryParameters = @($parameterSet.Parameters.Where({$_.IsMandatory -eq $true})).Name
            if ($mandatoryParameters.Count -gt 0) {
                # Remove each provided mandatory parameter from the list
                # so we can find any that will have to be coverd by positional parameters
                $this.LogDebug('Provided named parameters', $parsedCommand.NamedParameters.Keys)
                foreach ($providedNamedParameter in $parsedCommand.NamedParameters.Keys ) {
                    $this.LogDebug("Named parameter [$providedNamedParameter] provided")
                    $mandatoryParameters = @($mandatoryParameters.Where({$_ -ne $providedNamedParameter}))
                }
                if ($mandatoryParameters.Count -gt 0) {
                    if ($parsedCommand.PositionalParameters.Count -lt $mandatoryParameters.Count) {
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

            $this.LogDebug("Valid parameters for parameterset [$($parameterSet.Name)] - [$($validated.ToString())]")
            if ($validated) {
                break
            }
        }

        return $validated
    }

    # Check if command needs approval by checking against command expressions in the approval configuration
    # if peer approval is needed, always return $true regardless if calling user is in approval group
    [bool]ApprovalNeeded([CommandExecutionContext]$Context) {
        if ($Context.ApprovalState -ne [ApprovalState]::Approved) {
            foreach ($approvalConfig in $this._bot.Configuration.ApprovalConfiguration.Commands) {
                if ($Context.FullyQualifiedCommandName -like $approvalConfig.Expression) {

                    $approvalGroups = $this._bot.RoleManager.GetUserGroups($Context.ParsedCommand.From).Name
                    if (-not $approvalGroups) {
                        $approvalGroups = @()
                    }
                    $compareParams = @{
                        ReferenceObject  = $this.GetApprovalGroups($Context)
                        DifferenceObject = $approvalGroups
                        PassThru         = $true
                        IncludeEqual     = $true
                        ExcludeDifferent = $true
                    }
                    $inApprovalGroup = (Compare-Object @compareParams).Count -gt 0

                    $Context.ApprovalState = [ApprovalState]::Pending
                    $this.LogDebug("Execution context ID [$($Context.Id)] needs approval from group(s) [$(($compareParams.ReferenceObject) -join ', ')]")

                    if ($inApprovalGroup) {
                        if ($approvalConfig.PeerApproval) {
                            $this.LogDebug("Execution context ID [$($Context.Id)] needs peer approval")
                        } else {
                            $this.LogInfo("Peer Approval not needed to execute context ID [$($Context.Id)]")
                        }
                        return $approvalConfig.PeerApproval
                    } else {
                        $this.LogInfo("Approval needed to execute context ID [$($Context.Id)]")
                        return $true
                    }
                }
            }
        }

        return $false
    }

    # Get list of approval groups for a command that needs approval
    [string[]]GetApprovalGroups([CommandExecutionContext]$Context) {
        return ($this._bot.Configuration.ApprovalConfiguration.Commands.Where({
            $Context.FullyQualifiedCommandName -like $_.Expression
        })).ApprovalGroups
    }

    # Get all completed (succeeded or failed) jobs from the job tracker
    hidden [CommandExecutionContext[]]_GetCompletedContexts() {
        $jobs = $this._jobTracker.GetEnumerator().Where({
            ($_.Value.Complete -eq $true) -or
            ($_.Value.IsJob -and (($_.Value.Job.State -eq 'Completed') -or ($_.Value.Job.State -eq 'Failed')))
        }) | Select-Object -ExpandProperty Value
        return $jobs
    }
}
