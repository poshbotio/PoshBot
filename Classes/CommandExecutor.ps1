
# In charge of executing and tracking progress of commands
class CommandExecutor {

    [RoleManager]$RoleManager

    [int]$HistoryToKeep = 100

    # Recent history of commands executed
    [CommandHistory[]]$History = @()

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

        # Verify that all mandatory parameters have been provided
        if (-not $this.ValidateMandatoryParameters($ParsedCommand, $Command)) {
            $err = [CommandRequirementsNotMet]::New("Mandatory parameters for [$($Command.Name)] not provided.`nHelpText: $($Command.HelpText)")
            $r.Success = $false
            $r.Errors += $err
            Write-Error -Exception $err
            return $r
        }

        # Verify that the caller can execute this command and execute if authorized
        if ($Command.IsAuthorized($UserId, $this.RoleManager)) {
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
                        #write-host "$($hash | format-list | out-string)"

                        #$global:poshbotcmd = $hash

                        # # Wait for command to complete
                        # $done = $hash.job.AsyncWaitHandle.WaitOne()

                        # $result = $hash.ps.EndInvoke($hash.job)

                        # Write-host $result

                        # $r.Streams.Error = $hash.ps.Streams.Error.ReadAll()
                        # $r.Streams.Information = $hash.ps.Streams.Information.ReadAll()
                        # $r.Streams.Verbose = $hash.ps.Streams.Verbose.ReadAll()
                        # $r.Streams.Warning = $hash.ps.Streams.Warning.ReadAll()
                        # $r.Output = $result

                        # Write-Verbose -Message "Command results: `n$($r | ConvertTo-Json)"
                        # # Determine if job had any terminating errors
                        # if ($r.Streams.Error.Count -gt 0) {
                        #     $r.Success = $false
                        # } else {
                        #     $r.Success = $true
                        # }

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

                        #$r.Output = $Command.Invoke($ParsedCommand, $false)
                        #$r.Success = $true
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
        return $r
    }

    [void]TrackJob($job) {
        if (-not $this._JobTracker.ContainsKey($job.Name)) {
            $this._JobTracker.Add($job.Name, $job)
        }
    }

    # Add command result to history
    [void]AddToHistory([string]$CommandName, [string]$UserId, [CommandResult]$Result, [ParsedCommand]$ParsedCommand) {
        $this.History += [CommandHistory]::New($CommandName, $UserId, $Result, $ParsedCommand)

        # TODO
        # Implement rolling history
    }

    # Validate that all mandatory parameters have been provided
    [bool]ValidateMandatoryParameters([ParsedCommand]$ParsedCommand, [Command]$Command) {
        $functionInfo = $Command.FunctionInfo
        $matchedParamSet = $null

        #Write-Host "$($ParsedCommand.NamedParameters | out-string)"

        foreach ($parameterSet in $functionInfo.ParameterSets) {
            $mandatoryParameters = ($parameterSet.Parameters | where IsMandatory -eq $true).Name
            if ($mandatoryParameters) {
                #Write-Host $mandatoryParameters
                if ( -not @($mandatoryParameters| where {$ParsedCommand.NamedParameters.Keys -notcontains $_}).Count) {
                    return $true
                }
            } else {
                return $true
            }
        }
        return $false
    }

}