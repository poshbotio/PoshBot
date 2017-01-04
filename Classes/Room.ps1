
class Room {

    [string]$Id

    # The name of the room
    [string]$Name

    # The room topic
    [string]$Topic

    # Indicates if this room already exists or not
    [bool]$Exists

    # Indicates if this room has already been joined
    [bool]$Joined

    [hashtable]$Members = @{}

    Room() {}

    [string]Join() {
        throw 'Must Override Method'
    }

    [string]Leave() {
        throw 'Must Override Method'
    }

    [string]Create() {
        throw 'Must Override Method'
    }

    [string]Destroy() {
        throw 'Must Override Method'
    }

    [string]Invite([string[]]$Invitees) {
        throw 'Must Override Method'
    }
}
