
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

    [pscustomobject]Summarize() {
        return [pscustomobject]@{
            Id = $this.Id
            Complete = $this.Complete
            Result = $this.Result.Summarize()
            FullyQualifiedCommandName = $this.FullyQualifiedCommandName
            ParsedCommand = $this.ParsedCommand.Summarize()
            Message = $this.Message
            IsJob = $this.IsJob
            Started = $this.Started.ToUniversalTime().ToString('u')
            Ended = $this.Ended.ToUniversalTime().ToString('u')
        }
    }

    [string]ToJson() {
        return $this.Summarize() | ConvertTo-Json -Depth 10 -Compress
    }
 }
