
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
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Scope='Function', Target='*')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Scope='Function', Target='*')]
class Command : BaseLogger {

    # Unique (to the plugin) name of the command
    [string]$Name

    [string[]]$Aliases = @()

    [string]$Description

    [TriggerType]$TriggerType = [TriggerType]::Command

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

    # Cannot have a constructor called "Command". Lame
    # We need to set the Logger property separately
    # Command([Logger]$Logger) {
    #     $this.Logger = $Logger
    # }

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
            ManifestPath = $this.ManifestPath
            Function = $this.FunctionInfo
            ParsedCommand = $ParsedCommand
            ConfigurationDirectory = $script:ConfigurationDirectory
        }
        if ([TriggerType]::Command -in $this.Triggers.Type) {
            $options.NamedParameters = $ParsedCommand.NamedParameters
            $options.PositionalParameters = $ParsedCommand.PositionalParameters
        } elseIf ([TriggerType]::Regex -in $this.Triggers.Type) {
            $regex = [regex]$this.Triggers[0].Trigger
            $options.NamedParameters = @{
                Arguments = $regex.Match($ParsedCommand.CommandString).Groups | Select-Object -ExpandProperty Value
            }
            $options.PositionalParameters = @()
        }

        $fqCommand = "$($this.FunctionInfo.Module.name)\$($this.FunctionInfo.name)"

        if ($this.FunctionInfo) {
            $options.FunctionInfo = $this.FunctionInfo
        }

        if ($InvokeAsJob) {
            $this.LogDebug("Executing command [$fqCommand] as job")
            $fdt = Get-Date -Format FileDateTimeUniversal
            $jobName = "$($this.Name)_$fdt"
            $jobParams = @{
                Name = $jobName
                ScriptBlock = $outer
                ArgumentList = $options
            }
            return (Start-Job @jobParams)
        } else {
            $this.LogDebug("Executing command [$fqCommand] in current PS session")
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
        $isAuth = $false
        foreach ($perm in $perms) {
            $result = $this.AccessFilter.Authorize($perm.Name)
            if ($result.Authorized) {
                $this.LogDebug("User [$UserId] authorized to execute command [$($this.Name)] via permission [$($perm.Name)]")
                $isAuth = $true
                break
            }
        }

        if ($isAuth) {
            return $true
        } else {
            $this.LogDebug("User [$UserId] not authorized to execute command [$($this.name)]")
            return $false
        }
    }

    [void]Activate() {
        $this.Enabled = $true
        $this.LogDebug("Command [$($this.Name)] activated")
    }

    [void]Deactivate() {
        $this.Enabled = $false
        $this.LogDebug("Command [$($this.Name)] deactivated")
    }

    [void]AddPermission([Permission]$Permission) {
        $this.LogDebug("Adding permission [$($Permission.Name)] to [$($this.Name)]")
        $this.AccessFilter.AddPermission($Permission)
    }

    [void]RemovePermission([Permission]$Permission) {
        $this.LogDebug("Removing permission [$($Permission.Name)] from [$($this.Name)]")
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
                                $this.LogDebug("Parsed command [$($ParsedCommand.Command)] matched to command trigger [$($trigger.Trigger)] on command [$($this.Name)]")
                                $match = $true
                                break
                            }
                        }
                    }
                }
                'Event' {
                    if ($trigger.MessageType -eq $ParsedCommand.OriginalMessage.Type) {
                        if ($trigger.MessageSubtype -eq $ParsedCommand.OriginalMessage.Subtype) {
                            $this.LogDebug("Parsed command event type [$($ParsedCommand.OriginalMessage.Type.Tostring())`:$($ParsedCommand.OriginalMessage.Subtype.ToString())] matched to command trigger [$($trigger.MessageType.ToString())`:$($trigger.MessageSubtype.ToString())] on command [$($this.Name)]")
                            $match = $true
                            break
                        }
                    }
                }
                'Regex' {
                    if ($ParsedCommand.CommandString -match $trigger.Trigger) {
                        $this.LogDebug("Parsed command string [$($ParsedCommand.CommandString)] matched to regex trigger [$($trigger.Trigger)] on command [$($this.Name)]")
                        $match = $true
                        break
                    }
                }
            }
        }

        return $match
    }
}
