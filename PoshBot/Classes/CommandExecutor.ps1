
# In charge of executing and tracking progress of commands
class CommandExecutor : BaseLogger {

    [RoleManager]$RoleManager

    hidden [Bot]$_bot

    [int]$HistoryToKeep = 100

    [int]$ExecutedCount = 0

    # Recent history of commands executed
    [System.Collections.ArrayList]$History = (New-Object System.Collections.ArrayList)

    # Plugin commands get executed as PowerShell jobs
    # This is to keep track of those
    hidden [hashtable]$_jobTracker = @{}

    CommandExecutor([RoleManager]$RoleManager, [Logger]$Logger, [Bot]$Bot) {
        $this.RoleManager = $RoleManager
        $this.Logger = $Logger
        $this._bot = $Bot
    }

    # Execute a command
    [void]ExecuteCommand([CommandExecutionContext]$cmdExecContext) {

        # Verify command is not disabled
        if (-not $cmdExecContext.Command.Enabled) {
            $err = [CommandDisabled]::New("Command [$($cmdExecContext.Command.Name)] is disabled")
            $cmdExecContext.Complete = $true
            $cmdExecContext.Ended = (Get-Date).ToUniversalTime()
            $cmdExecContext.Result.Success = $false
            $cmdExecContext.Result.Errors += $err
            $this.LogInfo([LogSeverity]::Error, $err.Message, $err)
            $this.TrackJob($cmdExecContext)
            return
        }

        # Verify that all mandatory parameters have been provided for "command" type bot commands
        # This doesn't apply to commands triggered from regex matches, timers, or events
        if ($cmdExecContext.Command.TriggerType -eq [TriggerType]::Command) {
            if (-not $this.ValidateMandatoryParameters($cmdExecContext.ParsedCommand, $cmdExecContext.Command)) {
                $msg = "Mandatory parameters for [$($cmdExecContext.Command.Name)] not provided.`nUsage:`n"
                foreach ($usage in $cmdExecContext.Command.Usage) {
                    $msg += "    $usage`n"
                }
                $err = [CommandRequirementsNotMet]::New($msg)
                $cmdExecContext.Complete = $true
                $cmdExecContext.Ended = (Get-Date).ToUniversalTime()
                $cmdExecContext.Result.Success = $false
                $cmdExecContext.Result.Errors += $err
                $this.LogInfo([LogSeverity]::Error, $err.Message, $err)
                $this.TrackJob($cmdExecContext)
                return
            }
        }

        # If command is [command] or [regex] trigger types, verify that the caller is authorized to execute it
        if ($cmdExecContext.Command.TriggerType -in @('Command', 'Regex')) {
            $authorized = $cmdExecContext.Command.IsAuthorized($cmdExecContext.Message.From, $this.RoleManager)
        } else {
            $authorized = $true
        }

        if ($authorized) {

            # Check if approval(s) are needed to execute this command
            if ($this.ApprovalNeeded($cmdExecContext)) {
                $cmdExecContext.ApprovalState = [ApprovalState]::Pending
                $this._bot.Backend.AddReaction($cmdExecContext.Message, [ReactionType]::ApprovalNeeded)

                # Put this message in the deferred bucket until it is released by the [!approve] command from an authorized approver
                if (-not $this._bot.DeferredCommandExecutionContexts.ContainsKey($cmdExecContext.id)) {
                    $this._bot.DeferredCommandExecutionContexts.Add($cmdExecContext.id, $cmdExecContext)
                } else {
                    $this.LogInfo([LogSeverity]::Error, "This shouldn't happen, but command execution context [$($cmdExecContext.id)] is already in the deferred bucket")
                }

                $approverGroups = $this.GetApprovalGroups($cmdExecContext) -join ', '
                $prefix = $this._bot.Configuration.CommandPrefix
                $msg = "Approval is needed to run [$($cmdExecContext.ParsedCommand.CommandString)] from someone in the approval group(s) [$approverGroups]."
                $msg += "`nTo approve, say '$($prefix)approve $($cmdExecContext.Id)'."
                $msg += "`nTo deny, say '$($prefix)deny $($cmdExecContext.Id)'."
                $msg += "`nTo list pending approvals, say '$($prefix)pending'."
                $response = [Response]::new($cmdExecContext.Message)
                $response.Data = New-PoshBotCardResponse -Type Warning -Title "Approval Needed for [$($cmdExecContext.ParsedCommand.CommandString)]" -Text $msg
                $this._bot.SendMessage($response)
                return
            } else {

                # If command is [command] or [regex] trigger type, add reaction telling the user that the command is being executed
                # Reactions don't make sense for event triggered commands
                if ($cmdExecContext.Command.TriggerType -in @('Command', 'Regex')) {
                    if ($this._bot.Configuration.AddCommandReactions) {
                        $this._bot.Backend.AddReaction($cmdExecContext.Message, [ReactionType]::Processing)
                    }
                }

                if ($cmdExecContext.Command.AsJob) {
                    $this.LogDebug("Command [$($cmdExecContext.FullyQualifiedCommandName)] will be executed as a job")

                    # Kick off job and add to job tracker
                    $cmdExecContext.IsJob = $true
                    $cmdExecContext.Job = $cmdExecContext.Command.Invoke($cmdExecContext.ParsedCommand, $true,$this._bot.Backend.GetType().Name)
                    $this.LogDebug("Command [$($cmdExecContext.FullyQualifiedCommandName)] executing in job [$($cmdExecContext.Job.Id)]")
                    $cmdExecContext.Complete = $false
                } else {
                    # Run command in current session and get results
                    # This should only be 'builtin' commands
                    try {
                        $cmdExecContext.IsJob = $false
                        $hash = $cmdExecContext.Command.Invoke($cmdExecContext.ParsedCommand, $false,$this._bot.Backend.GetType().Name)
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
                        $this.LogVerbose("Command [$($cmdExecContext.FullyQualifiedCommandName)] completed with successful result [$($cmdExecContext.Result.Success)]")
                    } catch {
                        $cmdExecContext.Complete = $true
                        $cmdExecContext.Result.Success = $false
                        $cmdExecContext.Result.Errors = $_.Exception.Message
                        $cmdExecContext.Result.Streams.Error = $_.Exception.Message
                        $this.LogInfo([LogSeverity]::Error, $_.Exception.Message, $_)
                    }
                }
            }
        } else {
            $msg = "Command [$($cmdExecContext.Command.Name)] was not authorized for user [$($cmdExecContext.Message.From)]"
            $err = [CommandNotAuthorized]::New($msg)
            $cmdExecContext.Complete = $true
            $cmdExecContext.Result.Errors += $err
            $cmdExecContext.Result.Success = $false
            $cmdExecContext.Result.Authorized = $false
            $this.LogInfo([LogSeverity]::Error, $err.Message, $err)
            $this.TrackJob($cmdExecContext)
            return
        }

        $this.TrackJob($cmdExecContext)
    }

    # Add the command execution context to the job tracker
    # So the status and results of it can be checked later
    [void]TrackJob([CommandExecutionContext]$CommandContext) {
        if (-not $this._jobTracker.ContainsKey($CommandContext.Id)) {
            $this.LogVerbose("Adding job [$($CommandContext.Id)] to tracker")
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
                        $this.LogVerbose("Job [$($cmdExecContext.Id)] is complete")
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
                        } else {
                            $cmdExecContext.Result.Success = $true
                        }

                        $this.LogVerbose("Command [$($cmdExecContext.FullyQualifiedCommandName)] completed with successful result [$($cmdExecContext.Result.Success)]")

                        # Clean up the job
                        Remove-Job -Job $cmdExecContext.Job
                    } elseIf ($cmdExecContext.Job.State -eq 'Failed') {
                        $cmdExecContext.Complete = $true
                        $cmdExecContext.Result.Success = $false
                        $this.LogVerbose("Command [$($cmdExecContext.FullyQualifiedCommandName)] failed")
                    }
                }

                # Send a success, warning, or fail reaction
                if ($cmdExecContext.Command.TriggerType -in @('Command', 'Regex')) {
                    if ($this._bot.Configuration.AddCommandReactions) {
                        if (-not $cmdExecContext.Result.Success) {
                            $reaction = [ReactionType]::Failure
                        } elseIf ($cmdExecContext.Result.Streams.Warning.Count -gt 0) {
                            $reaction = [ReactionType]::Warning
                        } else {
                            $reaction = [ReactionType]::Success
                        }
                        $this._bot.Backend.AddReaction($cmdExecContext.Message, $reaction)
                    }
                }

                # Add to history
                if ($cmdExecContext.Command.KeepHistory) {
                    $this.AddToHistory($cmdExecContext)
                }

                $this.LogVerbose("Removing job [$($cmdExecContext.Id)] from tracker")
                $this._jobTracker.Remove($cmdExecContext.Id)

                # Remove the reaction specifying the command is in process
                if ($cmdExecContext.Command.TriggerType -in @('Command', 'Regex')) {
                    if ($this._bot.Configuration.AddCommandReactions) {
                        $this._bot.Backend.RemoveReaction($cmdExecContext.Message, [ReactionType]::Processing)
                    }
                }

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
    [void]AddToHistory([CommandExecutionContext]$CmdExecContext) {
        if ($this.History.Count -ge $this.HistoryToKeep) {
            $this.History.RemoveAt(0) > $null
        }
        $this.LogDebug("Adding command execution [$($CmdExecContext.Id)] to history")
        $this.History.Add($CmdExecContext)
    }

    # Validate that all mandatory parameters have been provided
    [bool]ValidateMandatoryParameters([ParsedCommand]$ParsedCommand, [Command]$Command) {
        $validated = $false

        if ($Command.FunctionInfo) {
            $parameterSets = $Command.FunctionInfo.ParameterSets
        } else {
            $parameterSets = $Command.CmdletInfo.ParameterSets
        }

        foreach ($parameterSet in $parameterSets) {
            $this.LogDebug("Validating parameters for parameter set [$($parameterSet.Name)]")
            $mandatoryParameters = @($parameterSet.Parameters | Where-Object {$_.IsMandatory -eq $true}).Name
            if ($mandatoryParameters.Count -gt 0) {
                # Remove each provided mandatory parameter from the list
                # so we can find any that will have to be coverd by positional parameters
                $this.LogDebug('Provided named parameters', $ParsedCommand.NamedParameters.Keys)
                foreach ($providedNamedParameter in $ParsedCommand.NamedParameters.Keys ) {
                    $this.LogDebug("Named parameter [$providedNamedParameter] provided")
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
                        ReferenceObject = $this.GetApprovalGroups($Context)
                        DifferenceObject = $approvalGroups
                        PassThru = $true
                        IncludeEqual = $true
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
        foreach ($approvalConfig in $this._bot.Configuration.ApprovalConfiguration.Commands) {
            if ($Context.FullyQualifiedCommandName -like $approvalConfig.Expression) {
                return $approvalConfig.ApprovalGroups
            }
        }
        return @()
    }
}
