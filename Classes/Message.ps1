
# A chat message that is received from the chat network
class Message {
    [string]$Id                 # MAY have this
    [string]$Type               # Type of message
    [string]$Text               # Text of message. This may be empty depending on the message type
    [string]$To
    [string]$From               # Who sent the message
    [hashtable]$Options         # Any other bits of information about a message. This will be backend specific
    [pscustomobject]$RawMessage # The raw message as received by the backend. This can be usefull for the backend
}

class UserEnterMessage : Message {}
class UserExitMessage : Message {}
class TopicChangeMessage : Message {}