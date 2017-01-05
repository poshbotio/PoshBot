
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

        if (-not $Command.Enabled) {
            throw [CommandDisabled]::New("Command [$($Command.Name)] is disabled")
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

                    # Determine if job had any terminating errors
                    if ($job.State -eq 'Failed' -or $r.Streams.Error.Count -gt 0) {
                        $r.Success = $false
                    } else {
                        $r.Success = $true
                    }
                } else {
                    try {
                        # Block here until job is complete
                        $r.Output = $Command.Invoke($ParsedCommand, $false)
                        $r.Success = $true
                    } catch {
                        $r.Success = $false
                        Write-Error $_
                    }
                }
            }
            $r.Duration = $jobDuration

            # Add command result to history
            $this.AddToHistory($Command.Name, $UserId, $r)
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
    [void]AddToHistory([string]$CommandName, [string]$UserId, [CommandResult]$Result) {
        $this.History += [CommandHistory]::New($CommandName, $UserId, $Result)

        # TODO
        # Implement rolling history
    }

}