@{
  PluginRepository = @('PSGallery')
  AlternateCommandPrefixSeperators = @(':',',',';')
  ModuleManifestsToLoad = @()
  Name = 'Cherry2000'
  BotAdmins = @('devblackops')
  LogLevel = 'Verbose'
  SendCommandResponseToPrivate = @()
  MuteUnknownCommand = $False
  AddCommandReactions = $true
  AlternateCommandPrefixes = @('bender','hal')
  CommandPrefix = '!'
  BackendConfiguration = @{}
  PluginConfiguration = @{}
}
