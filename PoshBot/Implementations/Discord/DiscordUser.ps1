enum DiscordPremiumType {
    # Includes app perks like animated emojis and avatars, but not games
    NitroClassic = 1

    # Tncludes app perks as well as the games subscription service
    Nitro = 2
}

enum DiscordVisibilityType {
    # Invisible to everyone except the user themselves
    None = 0

    # Visible to everyone
    Everyone = 1
}

class DiscordUser : Person {
    # The user's 4-digit discord-tag
    [string]$Discriminator

    # The user's avatar hash
    # https://discordapp.com/developers/docs/reference#image-formatting
    [string]$Avatar

    # Whether the user belongs to an OAuth2 application
    [bool]$IsBot

    # whether the user has two factor enabled on their account
    [bool]$IsMfaEnabled

    # The user's chosen language option
    [string]$Locale

    # Whether the email on this account has been verified
    [bool]$IsVerified

    # The user's email
    [string]$Email

    # The flags on a user's account
    # https://discordapp.com/developers/docs/resources/user#user-object-user-flags
    [int]$Flags

    # The type of Nitro subscription on a user's account
    # https://discordapp.com/developers/docs/resources/user#user-object-premium-types
    [int]$PremiumType
}
