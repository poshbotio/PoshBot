enum DiscordChannelType {
    GUILD_TEXT           = 0
    DM                   = 1
    GUILD_VOICE          = 2
    GROUP_DM             = 3
    GUILD_CATEGORY       = 4
    GUILD_NEWS           = 5
    GUILD_STORE          = 6
    GUILD_NEWS_THREAD    = 10
    GUILD_PUBLIC_THREAD  = 11
    GUILD_PRIVATE_THREAD = 12
    GUILD_STAGE_VOICE    = 13
}

class DiscordChannel : Room {
    # The type of channel
    [DiscordChannelType]$Type

    # The ID of the guild
    [string]$GuildId

    # Sorting position of the channel
    [int]$Position

    # Whether naught stuff can happen in the channel
    [bool]$NSFW

    # The ID of the last message sent in this channel (may not point to an existing or valid message)
    [string]$LastMessageId

    # The bitrate (in bits) of the voice channel
    [int]$Bitrate

    # The user limit of the voice channel
    [int]$UserLimit

    # amount of seconds a user has to wait before sending another message (0-21600)
    # Bots, as well as users with the permission manage_messages or manage_channel, are unaffected
    [int]$RateLimitPerUser

    # The recipients of the DM
    [DiscordUser[]]$Recipients

    # Icon hash
    [string]$Icon

    # ID of the DM creator
    [string]$OwnerId

    # Application ID of the group DM creator if it is bot-created
    [string]$ApplicationId

    # ID of the parent category for a channel
    [string]$ParentId

    # When the last pinned message was pinned
    [datetime]$LastPinTimestamp
}
