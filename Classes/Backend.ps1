
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

    # Change presence

    #[void]CallbackPresence([Presence]$Presence) {}

    #[void]CallbackRoomJoined([Room]$Room) {}

    #[void]CallbackRoomLeft([Room]$Room) {}

    #[void]CallbackRoomTopic([Room]$Room) {}

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

function New-PoshBotBackend {
    param(
        [parameter(Mandatory)]
        [string]$Name
    )

    $backend = [Backend]::New()
    $backend.Name = $Name
    return $backend
}