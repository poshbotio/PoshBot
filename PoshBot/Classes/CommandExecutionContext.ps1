
# Represents the state of a currently executing command
class CommandExecutionContext {
    [string]$Id = (New-Guid).ToString()
    [bool]$Complete = $false
    [CommandResult]$Result
    [string]$FullyQualifiedCommandName
    [Command]$Command
    [ParsedCommand]$ParsedCommand
    [Message]$Message
    [bool]$IsJob
    [datetime]$Started
    [datetime]$Ended
    [object]$Job
 }
