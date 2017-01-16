
Remove-Module PoshBot -Force -Verbose:$false -ErrorAction Ignore
Import-Module $PSScriptroot\PoshBot.psd1 -Force -Verbose:$false

$VerbosePreference = 'continue'
$DebugPreference = 'continue'

# Create a Slack backend and bot instance
$backend = New-PoshBotSlackBackend -Name 'SlackBackend' -BotToken $env:SLACK_TOKEN
$bot = New-PoshBotInstance -Name 'SlackBot' -Backend $backend -ConfigurationDirectory (Join-Path -Path $env:USERPROFILE -ChildPath '.poshbot')

# $moduleName = 'demo'
# $manifestPath = "$PSScriptRoot\Plugins\$moduleName\$($moduleName).psd1"
# $bot | Add-PoshBotPlugin -ModuleManifest $manifestPath

#$bot.Start()