
# Represents the state of a currently executing command
class CommandExecutionContext {
    [string]$Id = (New-Guid).ToString().Split('-')[0]
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
    [ApprovalState]$ApprovalState = [ApprovalState]::AutoApproved
    [Approver]$Approver = [Approver]::new()
    [Response]$Response = [Response]::new()

    [pscustomobject]Summarize() {
        return [pscustomobject]@{
            Id                        = $this.Id
            Complete                  = $this.Complete
            Result                    = $this.Result.Summarize()
            FullyQualifiedCommandName = $this.FullyQualifiedCommandName
            ParsedCommand             = $this.ParsedCommand.Summarize()
            Message                   = $this.Message
            IsJob                     = $this.IsJob
            Started                   = $this.Started.ToUniversalTime().ToString('u')
            Ended                     = $this.Ended.ToUniversalTime().ToString('u')
            ApprovalState             = $this.ApprovalState.ToString()
            Approver                  = $this.Approver
            Response                  = $this.Response.Summarize()
        }
    }

    [string]ToJson() {
        return $this.Summarize() | ConvertTo-Json -Depth 10 -Compress
    }
 }
