
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

    # Unique Id of command
    #[string]$Id

    # Unique (to the plugin) name of the command
    [string]$Name

    #[hashtable]$Subcommands = @{}

    # The type of message this command is designed to respond to
    # Most of the type, this will be EMPTY so the
    #[string]$MessageType

    [string]$Description

    #[string]$Trigger
    [Trigger]$Trigger

    [string]$HelpText

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

        $ts = [System.Math]::Truncate((Get-Date -Date (Get-Date) -UFormat %s))
        $jobName = "$($this.Name)_$ts"

        # Wrap the command scriptblock so we can splat parameters to it

        # The inner scriptblock gets passed in as a string so we must convert it back to a scriptblock
        # https://www.reddit.com/r/PowerShell/comments/3vwlog/nested_scriptblocks_and_invokecommand/?st=ix0wdgg5&sh=73baa0b2
        # $outer = {
        #     [cmdletbinding()]
        #     param(
        #         [hashtable]$Options
        #     )

        #     $named = $Options.NamedParameters
        #     $pos = $Options.PositionalParameters

        #     if ($Options.IsScriptBlock) {
        #         $sb = [scriptblock]::create($options.ScriptBlock)
        #         & $sb @named @pos
        #     } else {
        #         $inner = [scriptblock]::Create($Options.ScriptBlock)
        #         $ps = $inner.GetPowerShell()
        #         $ps.AddParameters($named) | Out-Null
        #         $ps.AddParameters($pos) | Out-Null
        #         $ps.Invoke()
        #     }
        # }

        $outer = {
            [cmdletbinding()]
            param(
                [hashtable]$Options
            )

            Import-Module -Name $Options.ManifestPath -Scope Local -Force -Verbose:$false

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
            $output = Invoke-Command -ScriptBlock $outer -ArgumentList $Options -ErrorVariable errors -InformationVariable information -WarningVariable warning -Verbose -NoNewScope
            #$ps = [PowerShell]::Create()
            #$ps.AddScript($outer) | Out-Null
            #$ps.AddArgument($Options) | Out-Null
            #$job = $ps.BeginInvoke()
            return @{
                Error = @($errors)
                Information = @($Information)
                Output = $output
                Warning = @($warning)
            }
            #return @{
            #    ps = $ps
            #    job = $job
            #}
            #$done = $job.AsyncWaitHandle.WaitOne()

            #$result = $ps.EndInvoke($job)
            #return $result
        }

        # if ($this.ModuleCommand) {
        #     $sb = $this.ModuleCommand
        # } elseif ($this.ScriptBlock) {
        #     $sb = $this.ScriptBlock
        #     $options.IsScriptBlock = $true
        # } elseif ($this.ScriptPath) {
        #     $sb = $this.ScriptPath
        # }
        # $options.ScriptBlock = $sb




        # if ($this.AsJob) {

        # } else {

        # }

        # block here until job is complete
        # $done = $job.AsyncWaitHandle.WaitOne()

        # $result = $ps.EndInvoke($job)
        # return $result

        #return Start-Job @jobParams
    }

    [bool]IsAuthorized([string]$UserId, [RoleManager]$RoleManager) {

        $userRoles = $RoleManager.GetUserRoles($UserId)
        if (-not $userRoles) {
            $userRoles = @('Anyone')
        }
        foreach ($userRole in $userRoles) {
            $result = $this.AccessFilter.AuthorizeRole($userRole)
            if ($result.Authorized) {
                return $true
            }
        }
        return $false

        # $userResult = $this.AccessFilter.AuthorizeUser($UserId)
        # if ($userResult.Authorized) {
        #     return $true
        # } else {
        #     # User not explicitly authorized.
        #     # Now check if any roles the user is a member of are
        #     $userRoles = $RoleManager.GetUserRoles($UserId)
        #     foreach ($userRole in $userRoles) {
        #         $roleResult = $this.AccessFilter.AuthorizeRole($userRole)
        #         if ($roleResult.Authorized) {
        #             return $true
        #         }
        #     }
        #     return $false
        # }
    }

    [void]Activate() {
        $this.Enabled = $true
    }

    [void]Deactivate() {
        $this.Enabled = $false
    }

    [void]AddSubCommand([Command]$Command) {
        $subCommandName = $null
        if ($Command.Name.Contains('-')) {
            $subCommandName = $Command.Name.Split('-')[0]
        } elseIf ($Command.Name.Contains('_')) {
            $subCommandName = $Command.Name.Split('_')[0]
        }
        if ($subCommandName) {
            if (-not $this.Subcommands.ContainsKey($subCommandName)) {
                $this.Subcommands.Add($subCommandName, $Command)
            }
        }
    }

    # Add a role
    [void]AddRole([Role]$Role) {
        $this.AccessFilter.AddAllowedRole($Role.Name)
    }

    # Remove a role
    [void]RemoveRole([Role]$Role) {
        $this.AccessFilter.RemoveAllowedRole($Role.Name)
    }

    # Returns TRUE/FALSE if this command matches a parsed command from the chat network
    [bool]TriggerMatch([ParsedCommand]$ParsedCommand) {

        Write-Verbose "Checking command [$($this.Name)] for trigger match"

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
