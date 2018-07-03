
# A response message that is sent back to the chat network.
class Response {
    [Severity]$Severity = [Severity]::Success
    [string[]]$Text
    [string]$MessageFrom
    [string]$To
    [Message]$OriginalMessage = [Message]::new()
    [pscustomobject[]]$Data = @()

    Response() {}

    Response([Message]$Message) {
        $this.MessageFrom = $Message.From
        $this.To = $Message.To
        $this.OriginalMessage = $Message
    }

    [pscustomobject] Summarize() {
        return [pscustomobject]@{
            Severity        = $this.Severity.ToString()
            Text            = $this.Text
            MessageFrom     = $this.MessageFrom
            To              = $this.To
            OriginalMessage = $this.OriginalMessage
            Data            = $this.Data
        }
    }
}
