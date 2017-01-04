
class Stream {
    [object[]]$Debug = @()
    [object[]]$Error = @()
    [object[]]$Information = @()
    [object[]]$Verbose = @()
    [object[]]$Warning = @()
}

# Represents the result of running a command
class CommandResult {
    [bool]$Success
    [exception[]]$Errors = @()
    [object[]]$Output = @()
    [Stream]$Streams = [Stream]::new()
    [bool]$Authorized = $true
    [timespan]$Duration
}
