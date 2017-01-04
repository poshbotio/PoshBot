# The Plugin class holds a list of commands that can be executed
# and manages the execution of them.

# Some custom exceptions dealing with plugins
class PluginException : Exception {
    PluginException() {}
    PluginException([string]$Message) : base($Message) {}
}

class PluginNotFoundException : PluginException {
    PluginNotFoundException() {}
    PluginNotFoundException([string]$Message) : base($Message) {}
}

class PluginDisabled : PluginException {
    PluginDisabled() {}
    PluginDisabled([string]$Message) : base($Message) {}
}

# Represents a fully qualified module command
class ModuleCommand {
    [string]$Module
    [string]$Command

    [string]ToString() {
        return "$($this.Module)\$($this.Command)"
    }
}

class Plugin {

    # Unique ID for the plugin
    #[string]$Id

    # Unique name for the plugin
    [string]$Name

    # Hashtable of commands available
    [hashtable]$Commands = @{}

    [int]$HistoryToKeep

    # Recent history of commands executed
    [CommandHistory[]]$History = @()

    [bool]$Enabled

    [hashtable]$Roles = @{}

    # Plugin commands get executed as PowerShell jobs
    # This is to keep track of those
    $JobTracker = @{}

    Plugin() {
        $this.Name = $this.GetType().Name
        $this.HistoryToKeep = 100
        $this.Enabled = $true
    }

    Plugin([string]$Name) {
        #$this.Id = $Id
        $this.Name = $Name
        $this.HistoryToKeep = 100
        $this.Enabled = $true
    }

    # Invoke a command
    [CommandResult]InvokeCommand([Command]$Command, [ParsedCommand]$ParsedCommand, [String]$CallerId) {

        # Our result
        $r = [CommandResult]::New()

        # Find the command
        $existingCommand = $this.FindCommand($Command)
        if (-not $existingCommand) {
            $r.Success = $false
            $r.Errors += [CommandNotFoundException]::New("Command [$($Command.Name)] not found in plugin [$($this.Name)]")
            return $r
        }

        if (-not $existingCommand.Enabled) {
            throw [CommandDisabled]::New("Command [$($Command.Name)] is disabled")
        }

        # Verify that the caller can execute this command and then execute if authorized
        #if ($existingCommand.Authorized($CallerId)) {
        if ($existingCommand.IsAuthorized($CallerId)) {
            $jobDuration = Measure-Command -Expression {
                if ($existingCommand.AsJob) {
                    $job = $existingCommand.Invoke($ParsedCommand, $true)

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
                        $r.Output = $existingCommand.Invoke($ParsedCommand, $false)
                        $r.Success = $true
                    } catch {
                        $r.Success = $false
                        Write-Error $_
                    }
                }
            }
            $r.Duration = $jobDuration

            # Add command result to history
            $this.AddToHistory($Command.Name, $CallerId, $r)
        } else {
            $r.Success = $false
            $r.Authorized = $false
            $r.Errors += [CommandNotAuthorized]::New("Command [$($Command.Name)] was not authorized for caller [$($CallerId)]")
        }
        return $r
    }

    # Find the command
    [Command]FindCommand([Command]$Command) {
        return $this.Commands.($Command.Name)
    }

    # Set (or add) an ACE to a command's ACL
    [void]SetCommandACE([Command]$Command, [AccessControlEntry]$ACE) {
        $existingCommand = $this.FindCommand($Command)
        if (-not $existingCommand) {
            throw [CommandNotFoundException]::New("Command [$($Command.Name)] not found in plugin [$($this.Name)]")
        } else {
            $existingCommand.SetCommandACE($ACE)
        }
    }

    # Remove an ACE from a command's ACL
    [void]RemoveCommandACE([Command]$Command, [AccessControlEntry]$ACE) {
        $existingCommand = $this.FindCommand($Command)
        if (-not $existingCommand) {
            throw [CommandNotFoundException]::New("Command [$($Command.Name)] not found in plugin [$($this.Name)]")
        } else {
            $existingCommand.RemoveCommandACE($ACE)
        }
    }

    # Add a PowerShell module to the plugin
    [void]AddModule([string]$ModuleName) {
        if (-not $this.Modules.ContainsKey($ModuleName)) {
            $this.Modules.Add($ModuleName, $null)
            $this.LoadModuleCommands($ModuleName)
        }
    }

    # Add a new command
    [void]AddCommand([Command]$Command) {
        if (-not $this.FindCommand($Command)) {
            $this.Commands.Add($Command.Name, $Command)
        }
    }

    # Remove an existing command
    [void]RemoveCommand([Command]$Command) {
        $existingCommand = $this.FindCommand($Command)
        if ($existingCommand) {
            $this.Commands.Remove($Command.Name)
        }
    }

    # Activate a command
    [void]ActivateCommand([Command]$Command) {
        $existingCommand = $this.FindCommand($Command)
        if ($existingCommand) {
            $existingCommand.Activate()
        }
    }

    # Deactivate a command
    [void]DeactivateCommand([Command]$Command) {
        $existingCommand = $this.FindCommand($Command)
        if ($existingCommand) {
            $existingCommand.Deactivate()
        }
    }

    # Add roles
    [void]AddRoles([Role[]]$Roles) {
        $Roles | ForEach-Object {
            $this.AddRole($_)
        }
    }

    # Add a role
    [void]AddRole([Role]$Role) {
        if (-not $this.Roles.ContainsKey($Role.Name)) {
            $this.Roles.Add($Role.Name, $Role)
        }
    }

    # Remove roles
    [void]RemoveRoles([Role[]]$Roles) {
        $Roles | ForEach-Object {
            $this.RemoveRole($_)
        }
    }

    # Remove a role
    [void]RemoveRole([Role]$Role) {
        if ($this.Roles.ContainsKey($Role.Name)) {
            $this.Roles.Remove($Role.Name, $Role)
        }
    }

    # Add command result to history
    [void]AddToHistory([string]$CommandName, [string]$CallerId, [CommandResult]$Result) {
        $this.History += [CommandHistory]::New($CommandName, $CallerId, $Result)

        # TODO
        # Implement rolling history
    }

    [void]TrackJob($job) {
        if (-not $this.JobTracker.ContainsKey($job.Name)) {
            $this.JobTracker.Add($job.Name, $job)
        }
    }

    # Activate plugin
    [void]Activate() {
        $this.Enabled = $true
    }

    # Deactivate plugin
    [void]Deactivate() {
        $this.Enabled = $false
    }
}

function New-PoshBotPlugin {
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        [string]$Name,

        [Command[]]$Commands = @(),

        [Role[]]$Roles = @()
    )

    $plugin = [Plugin]::new($Name)
    $Commands | foreach {
        $plugin.AddCommand($_)
    }
    $Roles | foreach {
        $plugin.AddRole($_)
    }
    return $plugin
}

function Add-PoshBotPluginCommand {
    [cmdletbinding()]
    param(
        [parameter(Mandatory, ValueFromPipeline)]
        [Alias('Plugin')]
        [Plugin]$InputObject,

        [parameter(Mandatory)]
        [Command]$Command
    )

    Write-Verbose -Message "Adding command [$($Command.Name)] to plugin"
    $InputObject.AddCommand($Command)
}
