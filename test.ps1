
Remove-Module PoshBot -Force -Verbose:$false -ErrorAction Ignore
Import-Module $PSScriptroot\PoshBot.psd1 -Force -Verbose:$false

$VerbosePreference = 'continue'
$DebugPreference = 'continue'

# Create the configuration
$config = New-PoshBotConfiguration -BotAdmins 'bolin' -CommandPrefix '!' -LogLevel 'Debug' -AlternateCommandPrefixes 'bender', 'hal' -LogDirectory (Join-Path -Path $env:USERPROFILE -ChildPath '.poshbot\Logs')
$configFile = $config | Save-PoshBotConfiguration -PassThru

# Create a Slack backend and bot instance
$backend = New-PoshBotSlackBackend -Name 'SlackBackend' -BotToken $env:SLACK_TOKEN
$bot = New-PoshBotInstance -Name 'SlackBot' -Backend $backend -ConfigurationDirectory $configFile.Directory.FullName
