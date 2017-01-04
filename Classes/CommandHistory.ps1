
class CommandHistory {

    # ID of command
    [string]$CommandId

    # ID of caller
    [string]$CallerId

    # Command results
    [CommandResult]$Result

    # Date/time command was executed
    [datetime]$Time

    CommandHistory([string]$CommandId, [string]$CallerId, [CommandResult]$Result) {
        $this.CommandId = $CommandId
        $this.CallerId = $CallerId
        $this.Result = $Result
        $this.Time = Get-Date
    }
}
