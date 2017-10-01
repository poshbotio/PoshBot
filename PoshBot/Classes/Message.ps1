
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
}
