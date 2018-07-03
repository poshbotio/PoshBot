
# A chat message that is received from the chat network
class Message {
    [string]$Id                 # MAY have this
    [MessageType]$Type = [MessageType]::Message
    [MessageSubtype]$Subtype = [MessageSubtype]::None    # Some messages have subtypes
    [string]$Text               # Text of message. This may be empty depending on the message type
    [string]$To                 # Id of user/channel the message is to
    [string]$ToName             # Name of user/channel the message is to
    [string]$From               # ID of user who sent the message
    [string]$FromName           # Name of user who sent the message
    [datetime]$Time             # The date/time (UTC) the message was received
    [bool]$IsDM                 # Denotes if message is a direct message
    [hashtable]$Options         # Any other bits of information about a message. This will be backend specific
    [pscustomobject]$RawMessage # The raw message as received by the backend. This can be usefull for the backend

    [Message]Clone () {
        $newMsg = [Message]::New()
        foreach ($prop in ($this | Get-Member -MemberType Property)) {
            if ('Clone' -in ($this.$($prop.Name) | Get-Member -MemberType Method -ErrorAction Ignore).Name) {
                $newMsg.$($prop.Name) = $this.$($prop.Name).Clone()
            } else {
                $newMsg.$($prop.Name) = $this.$($prop.Name)
            }
        }
        return $newMsg
    }

    [hashtable] ToHash() {
        return @{
            Id         = $this.Id
            Type       = $this.Type.ToString()
            Subtype    = $this.Subtype.ToString()
            Text       = $this.Text
            To         = $this.To
            ToName     = $this.ToName
            From       = $this.From
            FromName   = $this.FromName
            Time       = $this.Time.ToUniversalTime().ToString('u')
            IsDM       = $this.IsDM
            Options    = $this.Options
            RawMessage = $this.RawMessage
        }
    }

    [string] ToJson() {
        return $this.ToHash() | ConvertTo-Json -Depth 10 -Compress
    }
}
