
# This generic Backend class provides the base scaffolding to represent a Chat network
class Backend {

    [string]$Name

    [string]$BotId

    # Connection information for the chat network
    [Connection]$Connection

    [hashtable]$Users = @{}

    [hashtable]$Rooms = @{}

    [System.Collections.ArrayList]$IgnoredMessageTypes = (New-Object System.Collections.ArrayList)

    Backend() {}

    # Send a message
    # Must be extended by the specific Backend implementation
    [void]SendMessage([Response]$Response) {}


    # Receive a message
    # Must be extended by the specific Backend implementation
    [Event]ReceiveMessage() {
        $e = [Message]::New()
        return $e
    }

    # Send a ping on the chat network
    [void]Ping() {
        # Only implement this method to send a message back
        # to the chat network to keep the connection open
    }

    [Person]GetUser([string]$UserId) {
        return $null
    }

    # Connect to the chat network
    [void]Connect() {
        $this.Connection.Connect()
    }

    # Disconnect from the chat network
    [void]Disconnect() {
        $this.Connection.Disconnect()
    }

    [void]LoadUsers() {}

    [void]LoadRooms() {}

    [void]GetBotIdentity() {}

    # Resolve a user name to user id
    [void]UsernameToUserId([string]$Username) {
        # Must be extended by the specific Backend implementation
    }

    # Resolve a user ID to a username/nickname
    [void]UserIdToUsername([string]$UserId) {
        # Must be extended by the specific Backend implementation
    }
}
