
Remove-Module PoshBot -Force -Verbose:$false -ErrorAction Ignore
Import-Module $PSScriptroot\PoshBot.psd1 -Force -Verbose:$false

$VerbosePreference = 'continue'
#$DebugPreference = 'continue'

# # Start a interactive bot from a newly created configuration
# $botParams = @{
#     Name = 'Cherry2000'
#     BotAdmins = 'bolin'
#     CommandPrefix = '!'
#     LogLevel = 'Debug'
#     BackendConfiguration = @{
#         Token = $env:SLACK_TOKEN
#         Name = 'SlackBackend'
#     }
#     AlternateCommandPrefixes = 'bender', 'hal'
#     LogDirectory = (Join-Path -Path $env:USERPROFILE -ChildPath '.poshbot\Logs')
# }
# $config = New-PoshBotConfiguration @botParams

# Create a Slack backend
#$backend = New-PoshBotSlackBackend -Configuration $config.BackendConfiguration

#$configFile = $config | Save-PoshBotConfiguration -Path (Join-Path -Path $env:USERPROFILE -ChildPath '.poshbot\Cherry2000.psd1') -PassThru
#$config | Start-PoshBot

# # Get an existing configuration and start interactive bot
#$config = Get-PoshBotConfiguration -Path (Join-Path -Path $env:USERPROFILE -ChildPath '.poshbot\Cherry2000.psd1')
#$config | Start-PoshBot

#$config = Get-PoshBotConfiguration -Path (Join-Path -Path $env:USERPROFILE -ChildPath '.poshbot\Cherry2000.psd1')
#$backend = New-PoshBotSlackBackend -Configuration $config.BackendConfiguration
Start-PoshBot -ConfigurationPath (Join-Path -Path $env:USERPROFILE -ChildPath '.poshbot\Cherry2000.psd1')

# Start-PoshBot -(Join-Path -Path $env:USERPROFILE -ChildPath '.poshbot\Cherry2000.psd1')
#$bot = New-PoshBotInstance -Backend $backend -Configuration $config
