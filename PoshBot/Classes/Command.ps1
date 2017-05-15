
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

    [string[]]$Aliases = @()

    [string]$Description

    [Trigger[]]$Triggers = @()

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

            # Context for who/how the command was called
            $global:PoshBotContext = [pscustomobject]@{
                Plugin = $options.ParsedCommand.Plugin
                Command = $options.ParsedCommand.Command
                From = $options.ParsedCommand.From
                To = $options.ParsedCommand.To
                ConfigurationDirectory = $options.ConfigurationDirectory
                ParsedCommand = $options.ParsedCommand
            }

            & $func @named @pos
        }

        [string]$sb = [string]::Empty
        $options = @{
            NamedParameters = $ParsedCommand.NamedParameters
            PositionalParameters = $ParsedCommand.PositionalParameters
            ManifestPath = $this.ManifestPath
            Function = $this.FunctionInfo
            ParsedCommand = $ParsedCommand
            ConfigurationDirectory = $script:ConfigurationDirectory
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

    [void]AddPermission([Permission]$Permission) {
        $this.AccessFilter.AddPermission($Permission)
    }

    [void]RemovePermission([Permission]$Permission) {
        $this.AccessFilter.RemovePermission($Permission)
    }

    # Search all the triggers for this command and return TRUE if we have a match
    # with the parsed command
    [bool]TriggerMatch([ParsedCommand]$ParsedCommand, [bool]$CommandSearch = $true) {
        $match = $false
        foreach ($trigger in $this.Triggers) {
            switch ($trigger.Type) {
                'Command' {
                    if ($CommandSearch) {
                        # Command tiggers only work with normal messages received from chat network
                        if ($ParsedCommand.OriginalMessage.Type -eq [MessageType]::Message) {
                            if ($trigger.Trigger -eq $ParsedCommand.Command) {
                                $match = $true
                                break
                            }
                        }
                    }
                }
                'Event' {
                    if ($trigger.MessageType -eq $ParsedCommand.OriginalMessage.Type) {
                        if ($trigger.MessageSubtype -eq $ParsedCommand.OriginalMessage.Subtype) {
                            $match = $true
                            break
                        }
                    }
                }
                'Regex' {
                    if ($ParsedCommand.CommandString -match $trigger.Trigger) {
                        $match = $true
                        break
                    }
                }
            }
        }

        return $match
    }
}
