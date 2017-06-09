
# Some enums
enum AccessRight {
    Allow
    Deny
}

enum ConnectionStatus {
    Connected
    Disconnected
}

enum TriggerType {
    Command
    Event
    Regex
}

enum LogLevel {
    Info = 1
    Verbose = 2
    Debug = 4
}

enum ReactionType {
    Success
    Failure
    Processing
    Custom
}

# Unit of time for scheduled commands
enum TimeInterval {
    Days
    Hours
    Minutes
    Seconds
}