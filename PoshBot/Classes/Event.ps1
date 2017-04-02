
# An Event is something that happended on a chat network. A person joined a room, a message was received
# Really any notification from the chat network back to the bot is considered an Event of some sort
class Event {
    [string]$Type
    [string]$ChannelId
    [pscustomobject]$Data
}

