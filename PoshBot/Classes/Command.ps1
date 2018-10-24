
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
    [string]$ModuleQualifiedCommand

    [string]$ManifestPath

    [System.Management.Automation.FunctionInfo]$FunctionInfo

    [System.Management.Automation.CmdletInfo]$CmdletInfo

    [AccessFilter]$AccessFilter = [AccessFilter]::new()

    [bool]$Enabled = $true

    # Cannot have a constructor called "Command". Lame
    # We need to set the Logger property separately
    # Command([Logger]$Logger) {
    #     $this.Logger = $Logger
    # }

    # Execute the command in a PowerShell job and return the running job
    [object]Invoke([ParsedCommand]$ParsedCommand, [bool]$InvokeAsJob = $this.AsJob, [string]$Backend) {

        $outer = {
            [cmdletbinding()]
            param(
                [hashtable]$Options
            )

            Import-Module -Name $Options.PoshBotManifestPath -Force -Verbose:$false -WarningAction SilentlyContinue -ErrorAction Stop

            Import-Module -Name $Options.ManifestPath -Scope Local -Force -Verbose:$false -WarningAction SilentlyContinue

            $namedParameters = $Options.NamedParameters
            $positionalParameters = $Options.PositionalParameters

            # Context for who/how the command was called
            $parsedCommandExcludes = @('From', 'FromName', 'To', 'ToName', 'CallingUserInfo', 'OriginalMessage')
            $global:PoshBotContext = [pscustomobject]@{
                Plugin = $options.ParsedCommand.Plugin
                Command = $options.ParsedCommand.Command
                From = $options.ParsedCommand.From
                FromName = $options.ParsedCommand.FromName
                To = $options.ParsedCommand.To
                ToName = $options.ParsedCommand.ToName
                CallingUserInfo = $options.CallingUserInfo
                ConfigurationDirectory = $options.ConfigurationDirectory
                ParsedCommand = $options.ParsedCommand | Select-Object -ExcludeProperty $parsedCommandExcludes
                OriginalMessage = $options.OriginalMessage
                BackendType = $options.BackendType
            }

            & $Options.ModuleQualifiedCommand @namedParameters @positionalParameters
        }

        [string]$sb = [string]::Empty
        $options = @{
            ManifestPath = $this.ManifestPath
            ParsedCommand = $ParsedCommand
            CallingUserInfo = $ParsedCommand.CallingUserInfo
            OriginalMessage = $ParsedCommand.OriginalMessage.ToHash()
            ConfigurationDirectory = $script:ConfigurationDirectory
            BackendType = $Backend
            PoshBotManifestPath = (Join-Path -Path $script:moduleBase -ChildPath "PoshBot.psd1")
            ModuleQualifiedCommand = $this.ModuleQualifiedCommand
        }
        if ($this.FunctionInfo) {
            $options.Function = $this.FunctionInfo
        } elseIf ($this.CmdletInfo) {
            $options.Function = $this.CmdletInfo
        }

        # Add named/positional parameters
        $options.NamedParameters = $ParsedCommand.NamedParameters
        $options.PositionalParameters = $ParsedCommand.PositionalParameters

        if ($InvokeAsJob) {
            $this.LogDebug("Executing command [$($this.ModuleQualifiedCommand)] as job")
            $fdt = Get-Date -Format FileDateTimeUniversal
            $jobName = "$($this.Name)_$fdt"
            $jobParams = @{
                Name = $jobName
                ScriptBlock = $outer
                ArgumentList = $options
            }
            return (Start-Job @jobParams)
        } else {
            $this.LogDebug("Executing command [$($this.ModuleQualifiedCommand)] in current PS session")
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
        $isAuth = $false
        if ($this.AccessFilter.Permissions.Count -gt 0) {
            $perms = $RoleManager.GetUserPermissions($UserId)
            foreach ($perm in $perms) {
                $result = $this.AccessFilter.Authorize($perm.Name)
                if ($result.Authorized) {
                    $this.LogDebug("User [$UserId] authorized to execute command [$($this.Name)] via permission [$($perm.Name)]")
                    $isAuth = $true
                    break
                }
            }
        } else {
            $isAuth = $true
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
