enum DiscordMessageType {
  DEFAULT
  RECIPIENT_ADD
  RECIPIENT_REMOVE
  CALL
  CHANNEL_NAME_CHANGE
  CHANNEL_ICON_CHANGE
  CHANNEL_PINNED_MESSAGE
  GUILD_MEMBER_JOIN
}

class DiscordMessage : Message {
  [DiscordMessageType]$MessageType = [DiscordMessageType]::DEFAULT

  DiscordMessage(
    [string]$Content = [string]::Empty,
    [bool]$Tts       = $false
  ) {
    $this.Content = $Content
    $this.Tts     = $Tts
  }

}
