
# In charge of executing and tracking progress of commands
class CommandExecutor {

    [RoleManager]$RoleManager

    [int]$HistoryToKeep = 100

    [int]$ExecutedCount = 0

    # Recent history of commands executed
    [System.Collections.ArrayList]$History = (New-Object System.Collections.ArrayList)

    # Plugin commands get executed as PowerShell jobs
    # This is to keep track of those
    hidden [hashtable]$_JobTracker = @{}

    CommandExecutor([RoleManager]$RoleManager) {
        $this.RoleManager = $RoleManager
    }

    # Invoke a command
    # Should this live in the Plugin or in the main bot class?
    [CommandResult]ExecuteCommand([Command]$Command, [ParsedCommand]$ParsedCommand, [String]$UserId) {

        # Our result
        $r = [CommandResult]::New()

        # Verify command is not disabled
        if (-not $Command.Enabled) {
            $err = [CommandDisabled]::New("Command [$($Command.Name)] is disabled")
            $r.Success = $false
            $r.Errors += $err
            Write-Error -Exception $err
            return $r
        }

        # Verify that all mandatory parameters have been provided for "command" type bot commands
        # This doesn't apply to commands triggered from regex matches, timers, or events
        if ($Command.Trigger.Type -eq [TriggerType]::Command) {
            if (-not $this.ValidateMandatoryParameters($ParsedCommand, $Command)) {
                $msg = "Mandatory parameters for [$($Command.Name)] not provided.`nUsage:`n"
                foreach ($usage in $Command.Usage) {
                    $msg += "    $usage`n"
                }
                $err = [CommandRequirementsNotMet]::New($msg)
                $r.Success = $false
                $r.Errors += $err
                Write-Error -Exception $err
                return $r
            }
        }

        # If command is [command] type verify that the caller is authorized to execute command
        if ($Command.Trigger.Type -eq [TriggerType]::Command) {
            $authorized = $Command.IsAuthorized($UserId, $this.RoleManager)
        } else {
            $authorized = $true
        }

        if ($authorized) {
            $jobDuration = Measure-Command -Expression {
                if ($existingCommand.AsJob) {
                    $job = $Command.Invoke($ParsedCommand, $true)

                    # TODO
                    # Tracking the job will be used later so we can continue on
                    # without having to wait for the job to complete
                    #$this.TrackJob($job)

                    $job | Wait-Job

                    # Capture all the streams
                    $r.Streams.Error = $job.ChildJobs[0].Error.ReadAll()
                    $r.Streams.Information = $job.ChildJobs[0].Information.ReadAll()
                    $r.Streams.Verbose = $job.ChildJobs[0].Verbose.ReadAll()
                    $r.Streams.Warning = $job.ChildJobs[0].Warning.ReadAll()
                    $r.Output = $job.ChildJobs[0].Output.ReadAll()

                    Write-Verbose -Message "Command results: `n$($r | ConvertTo-Json)"

                    # Determine if job had any terminating errors
                    if ($job.State -eq 'Failed' -or $r.Streams.Error.Count -gt 0) {
                        $r.Success = $false
                    } else {
                        $r.Success = $true
                    }
                } else {
                    try {
                        $hash = $Command.Invoke($ParsedCommand, $false)
                        $r.Errors = $hash.Error
                        $r.Streams.Error = $hash.Error
                        $r.Streams.Information = $hash.Information
                        $r.Streams.Warning = $hash.Warning
                        $r.Output = $hash.Output
                        if ($r.Errors.Count -gt 0) {
                            $r.Success = $false
                        } else {
                            $r.Success = $true
                        }
                    } catch {
                        $r.Success = $false
                        $r.Errors = $_.Exception.Message
                        $r.Streams.Error = $_.Exception.Message
                    }
                }
            }
            $r.Duration = $jobDuration

            # Add command result to history
            if ($Command.KeepHistory) {
                $this.AddToHistory($Command.Name, $UserId, $r, $ParsedCommand)
            }
        } else {
            $r.Success = $false
            $r.Authorized = $false
            $r.Errors += [CommandNotAuthorized]::New("Command [$($Command.Name)] was not authorized for user [$($UserId)]")
        }

        # Track number of commands executed
        if ($r.Success) {
            $this.ExecutedCount++
        }
        return $r
    }

    [void]TrackJob($job) {
        if (-not $this._JobTracker.ContainsKey($job.Name)) {
            $this._JobTracker.Add($job.Name, $job)
        }
    }

    # Add command result to history
    [void]AddToHistory([string]$CommandName, [string]$UserId, [CommandResult]$Result, [ParsedCommand]$ParsedCommand) {
        #$this.History += [CommandHistory]::New($CommandName, $UserId, $Result, $ParsedCommand)
        if ($this.History.Count -ge $this.HistoryToKeep) {
            $this.History.RemoveAt(0) > $null
        }
        $this.History.Add([CommandHistory]::New($CommandName, $UserId, $Result, $ParsedCommand))
    }

    # Validate that all mandatory parameters have been provided
    [bool]ValidateMandatoryParameters([ParsedCommand]$ParsedCommand, [Command]$Command) {
        $functionInfo = $Command.FunctionInfo
        $matchedParamSet = $null

        $validated = $false
        foreach ($parameterSet in $functionInfo.ParameterSets) {
            Write-Verbose -Message "[CommandExecutor:ValidateMandatoryParameters] Validating parameters for parameter set [$($parameterSet.Name)]"
            $mandatoryParameters = @($parameterSet.Parameters | where IsMandatory -eq $true).Name
            if ($mandatoryParameters.Count -gt 0) {
                # Remove each provided mandatory parameter from the list
                # so we can find any that will have to be coverd by positional parameters

                Write-Verbose -Message "Provided named parameters: $($ParsedCommand.NamedParameters.Keys | Format-List | Out-String)"
                foreach ($providedNamedParameter in $ParsedCommand.NamedParameters.Keys ) {
                    Write-Verbose -Message "Named parameter [$providedNamedParameter] provided"
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

            Write-Verbose -Message "[CommandExecutor:ValidateMandatoryParameters] Valid parameters for parameterset [$($parameterSet.Name)] [$($validated.ToString())]"
            if ($validated) {
                break
            }
        }

        return $validated
    }
}
