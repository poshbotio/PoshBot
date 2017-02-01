
# Some custom exceptions dealing with executing commands
class CommandException : Exception {
    CommandException() {}
    CommandException([string]$Message) : base($Message) {}
}
class CommandNotFoundException : CommandException {
    CommandNotFoundException() {}
    CommandNotFoundException([string]$Message) : base($Message) {}
}
class CommandFailed : CommandException {
    CommandFailed() {}
    CommandFailed([string]$Message) : base($Message) {}
}
class CommandDisabled : CommandException {
    CommandDisabled() {}
    CommandDisabled([string]$Message) : base($Message) {}
}
class CommandNotAuthorized : CommandException {
    CommandNotAuthorized() {}
    CommandNotAuthorized([string]$Message) : base($Message) {}
}
class CommandRequirementsNotMet : CommandException {
    CommandRequirementsNotMet() {}
    CommandRequirementsNotMet([string]$Message) : base($Message) {}
}

# Represent a command that can be executed
class Command {

    # Unique (to the plugin) name of the command
    [string]$Name

    #[hashtable]$Subcommands = @{}

    [string]$Description

    [Trigger]$Trigger

    [string[]]$Usage

    [bool]$KeepHistory = $true

    [bool]$HideFromHelp = $false

    [bool]$AsJob = $true

    # Fully qualified name of a cmdlet or function in a module to execute
    [string]$ModuleCommand

    [string]$ManifestPath

    [System.Management.Automation.FunctionInfo]$FunctionInfo

    [AccessFilter]$AccessFilter = [AccessFilter]::new()

    [bool]$Enabled = $true

    # Execute the command in a PowerShell job and return the running job
    [object]Invoke([ParsedCommand]$ParsedCommand, [bool]$InvokeAsJob = $this.AsJob) {

        $outer = {
            [cmdletbinding()]
            param(
                [hashtable]$Options
            )

            Import-Module -Name $Options.ManifestPath -Scope Local -Force -Verbose:$false -WarningAction SilentlyContinue

            $named = $Options.NamedParameters
            $pos = $Options.PositionalParameters
            $func = $Options.Function

            & $func @named @pos
        }

        [string]$sb = [string]::Empty
        $options = @{
            NamedParameters = $ParsedCommand.NamedParameters
            PositionalParameters = $ParsedCommand.PositionalParameters
            ManifestPath = $this.ManifestPath
            Function = $this.FunctionInfo
        }
        if ($this.FunctionInfo) {
            $options.FunctionInfo = $this.FunctionInfo
        }

        if ($InvokeAsJob) {
            $fdt = Get-Date -Format FileDateTimeUniversal
            $jobName = "$($this.Name)_$fdt"
            $jobParams = @{
                Name = $jobName
                ScriptBlock = $outer
                ArgumentList = $options
            }
            return (Start-Job @jobParams)
        } else {
            $errors = $null
            $information = $null
            $warning = $null
            New-Variable -Name opts -Value $options
            $cmdParams = @{
                ScriptBlock = $outer
                ArgumentList = $Options
                ErrorVariable = 'errors'
                InformationVariable = 'information'
                WarningVariable = 'warning'
                Verbose = $true
                NoNewScope = $true
            }
            $output = Invoke-Command @cmdParams
            return @{
                Error = @($errors)
                Information = @($Information)
                Output = $output
                Warning = @($warning)
            }
        }
    }

    [bool]IsAuthorized([string]$UserId, [RoleManager]$RoleManager) {
        $perms = $RoleManager.GetUserPermissions($UserId)
        foreach ($perm in $perms) {
            $result = $this.AccessFilter.Authorize($perm.Name)
            if ($result.Authorized) {
                return $true
            }
        }

        return $false
    }

    [void]Activate() {
        $this.Enabled = $true
    }

    [void]Deactivate() {
        $this.Enabled = $false
    }

    # [void]AddSubCommand([Command]$Command) {
    #     $subCommandName = $null
    #     if ($Command.Name.Contains('-')) {
    #         $subCommandName = $Command.Name.Split('-')[0]
    #     } elseIf ($Command.Name.Contains('_')) {
    #         $subCommandName = $Command.Name.Split('_')[0]
    #     }
    #     if ($subCommandName) {
    #         if (-not $this.Subcommands.ContainsKey($subCommandName)) {
    #             $this.Subcommands.Add($subCommandName, $Command)
    #         }
    #     }
    # }

    [void]AddPermission([Permission]$Permission) {
        $this.AccessFilter.AddPermission($Permission)
    }

    [void]RemovePermission([Permission]$Permission) {
        $this.AccessFilter.RemovePermission($Permission)
    }

    # Returns TRUE/FALSE if this command matches a parsed command from the chat network
    [bool]TriggerMatch([ParsedCommand]$ParsedCommand) {
        switch ($this.Trigger.Type) {
            'Command' {
                # Command tiggers only work with normal messages received from chat network
                if ($ParsedCommand.OriginalMessage.Type -eq [MessageType]::Message) {
                    if ($this.Trigger.Trigger -eq $ParsedCommand.Command) {
                            return $true
                        } else {
                            return $false
                    }
                } else {
                    return $false
                }
            }
            'Event' {
                if ($this.Trigger.MessageType -eq $ParsedCommand.OriginalMessage.Type) {
                    if ($this.Trigger.MessageSubtype -eq $ParsedCommand.OriginalMessage.Subtype) {
                        return $true
                    }
                } else {
                    return $false
                }
            }
            'Regex' {
                if ($ParsedCommand.CommandString -match $this.Trigger.Trigger) {
                    return $true
                } else {
                    return $false
                }
            }
        }
        return $false
    }
}
