[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Scope='Class', Target='*')]
class DiscordBackend : Backend {
  # Types of Messages that we care about from Discord
  # All others will be ignored
  [string[]]$EventTypes = @(
    'HELLO'
    'READY'
    'RESUMED'
    'INVALID_SESSION'
    'CHANNEL_PINS_UPDATE'
    'MESSAGE_CREATE'
    'MESSAGE_UPDATE'
    'MESSAGE_DELETE'
    'MESSAGE_REACTION_ADD'
    'MESSAGE_REACTION_REMOVE'
    'PRESENCE_UPDATE'
  )

  [int]$MaxMessageLength = 4000

  DiscordBackend ([string]$Token) {
    $Configuration            = [ConnectionConfig]::new()
    $SecurityToken            = $Token | ConvertTo-SecureString -AsPlainText -Force
    $Configuration.Credential = New-Object System.Management.Automation.PSCredential('asdf', $SecurityToken)
    $Connection               = [DiscordConnection]::New()
    $Connection.Config        = $Config
    $this.Connection          = $Connection
  }

  # Connect to Discord
  [void]Connect() {
    $this.LogInfo('Connecting to backend')
    $this.LogInfo('Listening for the following event types. All others will be ignored', $this.EventTypes)
    $this.Connection.Connect()
    $This.Bot
  }
}