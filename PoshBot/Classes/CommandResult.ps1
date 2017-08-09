
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
    [object[]]$Errors = @()
    [object[]]$Output = @()
    [Stream]$Streams = [Stream]::new()
    [bool]$Authorized = $true
    [timespan]$Duration

    [pscustomobject]Summarize() {
        return [pscustomobject]@{
            Success = $this.Success
            Output = $this.Output
            Errors = foreach ($item in $this.Errors) {
                # Summarize exceptions so they can be serialized to json correctly
                if ($item -is [System.Management.Automation.ErrorRecord]) {
                    [ExceptionFormatter]::Summarize($item)
                } else {
                    $item
                }
            }
            Authorized = $this.Authorized
            Duration = $this.Duration.TotalSeconds
        }
    }

    [string]ToJson() {
        return $this.Summarize() | ConvertTo-Json -Depth 10 -Compress
    }
}
