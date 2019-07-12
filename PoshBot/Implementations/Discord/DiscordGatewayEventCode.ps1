enum DiscordGatewayEventCode {
    # We're not sure what went wrong. Try reconnecting?
    UnknownError = 4000

    # You sent an invalid Gateway opcode or an invalid payload for an opcode. Don't do that!
    UnknownOpcode = 4001

    # You sent an invalid payload to us. Don't do that!
    DocodeError = 4002

    # You sent us a payload prior to identifying
    NotAuthenticated = 4003

    # The account token sent with your identify payload is incorrect
    AuthenticationFailed = 4004

    # You sent more than one identify payload. Don't do that!
    AlreadyAuthenticated = 4005

    # The sequence sent when resuming the session was invalid. Reconnect and start a new session.
    InvalidSeq = 4007

    # Woah nelly! You're sending payloads to us too quickly. Slow it down!
    RateLimited = 4008

    # Your session timed out. Reconnect and start a new one.
    SessionTimeout = 4009

    # You sent us an invalid shard when identifying.
    InvalidShard = 4010

    # The session would have handled too many guilds - you are required to shard your connection in order to connect.
    ShardingRequired = 4011
}
