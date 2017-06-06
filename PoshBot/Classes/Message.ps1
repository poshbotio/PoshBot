
enum MessageType {
    ChannelRenamed
    Message
    PinAdded
    PinRemoved
    PresenceChange
    ReactionAdded
    ReactionRemoved
    StarAdded
    StarRemoved
}

enum MessageSubtype {
    None
    ChannelJoined
    ChannelLeft
    ChannelRenamed
    ChannelPurposeChanged
    ChannelTopicChanged
}

# A chat message that is received from the chat network
class Message {
    [string]$Id                 # MAY have this
    [MessageType]$Type = [MessageType]::Message
    [MessageSubtype]$Subtype = [MessageSubtype]::None    # Some messages have subtypes
    [string]$Text               # Text of message. This may be empty depending on the message type
    [string]$To
    [string]$From               # Who sent the message
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

class UserEnterMessage : Message {}
class UserExitMessage : Message {}
class TopicChangeMessage : Message {}