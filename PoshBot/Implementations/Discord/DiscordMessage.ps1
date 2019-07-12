enum DiscordMessageType {
    DEFAULT = 0
    RECIPIENT_ADD = 1
    RECIPIENT_REMOVE = 2
    CALL = 3
    CHANNEL_NAME_CHANGE = 4
    CHANNEL_ICON_CHANGE = 5
    CHANNEL_PINNED_MESSAGE = 6
    GUILD_MEMBER_JOIN = 7
    USER_PREMIUM_GUILD_SUBSCRIPTION = 8
    USER_PREMIUM_GUILD_SUBSCRIPTION_TIER_1 = 9
    USER_PREMIUM_GUILD_SUBSCRIPTION_TIER_2 = 10
    USER_PREMIUM_GUILD_SUBSCRIPTION_TIER_3 = 11
}

class DiscordMessage : Message {
    [DiscordMessageType]$MessageType = [DiscordMessageType]::DEFAULT

    DiscordMessage(
        [string]$To,
        [string]$From,
        [string]$Text = [string]::Empty
    ) {
        $this.To   = $To
        $this.From = $From
        $this.Text = $Text
    }
}
