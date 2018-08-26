
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

enum Severity {
    Success
    Warning
    Error
    None
}

enum LogLevel {
    Info = 1
    Verbose = 2
    Debug = 4
}

enum LogSeverity {
    Normal
    Warning
    Error
}

enum ReactionType {
    Success
    Failure
    Processing
    Custom
    Warning
    ApprovalNeeded
    Cancelled
    Denied
}

# Unit of time for scheduled commands
enum TimeInterval {
    Days
    Hours
    Minutes
    Seconds
}

enum ApprovalState {
    AutoApproved
    Pending
    Approved
    Denied
}

enum MessageType {
    CardClicked
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

enum MiddlewareType {
    PreReceive
    PostReceive
    PreExecute
    PostExecute
    PreResponse
    PostResponse
}
