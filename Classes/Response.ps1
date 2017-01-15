enum Severity {
    Success
    Warning
    Error
    None
}

# A response message that is sent back to the chat network.
class Response {
    [Severity]$Severity = [Severity]::Success
    [string[]]$Text
    [string]$MessageFrom
    [string]$To
    [pscustomobject[]]$Data = @()
}
