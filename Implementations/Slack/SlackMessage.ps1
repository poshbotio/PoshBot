enum SlackMessageType {
    Normal
    Error
    Warning
}

class SlackMessage : Message {

    [SlackMessageType]$MessageType = [SlackMessageType]::Normal

    SlackMessage(
        [string]$To,
        [string]$From,
        [string]$Body = [string]::Empty
    ) {
        $this.To = $To
        $this.From = $From
        $this.Body = $Body
    }

}
