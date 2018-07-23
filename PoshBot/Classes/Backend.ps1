
# This generic Backend class provides the base scaffolding to represent a chat network
class Backend : BaseLogger {

    [string]$Name

    [string]$BotId

    # Connection information for the chat network
    [Connection]$Connection

    [hashtable]$Users = @{}

    [hashtable]$Rooms = @{}

    [System.Collections.ArrayList]$IgnoredMessageTypes = (New-Object System.Collections.ArrayList)

    [bool]$LazyLoadUsers = $false

    Backend() {}

    # Send a message
    [void]SendMessage([Response]$Response) {
        # Must be extended by the specific Backend implementation
        throw 'Implement me!'
    }

    # Add a reaction to an existing chat message
    [void]AddReaction([Message]$Message, [ReactionType]$Type, [string]$Reaction) {
        # Must be extended by the specific Backend implementation
        throw 'Implement me!'
    }

    [void]AddReaction([Message]$Message, [ReactionType]$Type) {
        $this.AddReaction($Message, $Type, [string]::Empty)
    }

    # Add a reaction to an existing chat message
    [void]RemoveReaction([Message]$Message, [ReactionType]$Type, [string]$Reaction) {
        # Must be extended by the specific Backend implementation
        throw 'Implement me!'
    }

    [void]RemoveReaction([Message]$Message, [ReactionType]$Type) {
        $this.RemoveReaction($Message, $Type, [string]::Empty)
    }

    # Receive a message
    [Message[]]ReceiveMessage() {
        # Must be extended by the specific Backend implementation
        throw 'Implement me!'
    }

    # Send a ping on the chat network
    [void]Ping() {
        # Only implement this method to send a message back
        # to the chat network to keep the connection open
    }

    # Get a user by their Id
    [Person]GetUser([string]$UserId) {
        # Must be extended by the specific Backend implementation
        throw 'Implement me!'
    }

    # Connect to the chat network
    [void]Connect() {
        $this.Connection.Connect()
    }

    # Disconnect from the chat network
    [void]Disconnect() {
        $this.Connection.Disconnect()
    }

    # Populate the list of users on the chat network
    [void]LoadUsers() {
        # Must be extended by the specific Backend implementation
        throw 'Implement me!'
    }

    # Populate the list of channel or rooms on the chat network
    [void]LoadRooms() {
        # Must be extended by the specific Backend implementation
        throw 'Implement me!'
    }

    # Get the bot identity Id
    [string]GetBotIdentity() {
        # Must be extended by the specific Backend implementation
        throw 'Implement me!'
    }

    # Resolve a user name to user id
    [string]UsernameToUserId([string]$Username) {
        # Must be extended by the specific Backend implementation
        throw 'Implement me!'
    }

    # Resolve a user ID to a username/nickname
    [string]UserIdToUsername([string]$UserId) {
        # Must be extended by the specific Backend implementation
        throw 'Implement me!'
    }

    [hashtable]GetUserInfo([string]$UserId) {
        # Must be extended by the specific Backend implementation
        throw 'Implement me!'
    }

    [string]ChannelIdToName([string]$ChannelId) {
        # Must be extended by the specific Backend implementation
        throw 'Implement me!'
    }
}
