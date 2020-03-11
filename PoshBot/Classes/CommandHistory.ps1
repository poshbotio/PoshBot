
class CommandHistory {
    [string]$Id

    # ID of command
    [string]$CommandId

    # ID of caller
    [string]$CallerId

    # Command results
    [CommandResult]$Result

    [ParsedCommand]$ParsedCommand

    # Date/time command was executed
    [datetime]$Time

    CommandHistory([string]$CommandId, [string]$CallerId, [CommandResult]$Result, [ParsedCommand]$ParsedCommand) {
        $this.Id = (New-Guid).ToString() -Replace '-', ''
        $this.CommandId = $CommandId
        $this.CallerId = $CallerId
        $this.Result = $Result
        $this.ParsedCommand = $ParsedCommand
        $this.Time = [datetime]::UtcNow
    }
}
