enum DiscordPremiumType {
  NitroClassic = 1
  Nitro = 2
}

class DiscordPerson : Person {
  [string]$ID
  [string]$Username
  [string]$Discriminator
  [string]$Avatar
  [bool]$IsBot
  [bool]$IsMfaEnabled
  [string]$Locale
  [bool]$IsVerified
  [string]$Email
  [int]$Flags
  [int]$PremiumType
}