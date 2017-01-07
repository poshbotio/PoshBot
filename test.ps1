
Remove-Module PoshBot -Force -Verbose:$false -ErrorAction SilentlyContinue
Import-Module $PSScriptroot\PoshBot.psd1 -Force -Verbose:$false

$VerbosePreference = 'continue'
$DebugPreference = 'continue'

# Create a Slack backend and bot instance
$backend = New-PoshBotSlackBackend -Name 'SlackBackend' -BotToken $env:SLACK_TOKEN
$bot = New-PoshBotInstance -Name 'SlackBot' -Backend $backend

# # Create a new plugin with some commands
# $plugin1Roles = 'plugin1:hello', 'plugin1:time', 'plugin1:dosomething' | % {
#     New-PoshBotRole -Name $_
# }
# $plugin1 =  New-PoshBotPlugin -Name 'Plugin1' -Roles $plugin1Roles
# $c1 = New-PoshBotCommand -Name 'hello' `
#                             -Trigger (New-PoshBotTrigger -Type 'Command' -Trigger 'hello') `
#                             -Description 'Says hello' `
#                             -HelpText '!plugin1:hello --name Brandon' `
#                             -ScriptBlock {
#                             param(
#                                 [string]$Name
#                             )
#                             "Hello $Name!"
#                             }
# $c2 = New-PoshBotCommand -Name 'time' `
#                             -Trigger (New-PoshBotTrigger -Type 'Command' -Trigger 'time') `
#                             -Description 'Gets the current time' `
#                             -HelpText '!plugin1:time' `
#                             -ScriptBlock {
#                             $time = Get-Date
#                             "The time is $(($time).ToShortTimeString())"
#                             }
# $c2.AccessFilter.AddAllowedRole($plugin1Roles[1].Name)
# $c2.AccessFilter.AddDeniedUser('U1QAMMBCH')
# #$bot.RoleManager.AddUserToRole('U1QAMMBCH', $plugin1Roles[1].Name)
# $bot.RoleManager.AddUserToRole('U1QAMMBCH', 'plugin1:time')

# $c5 = New-PoshBotCommand -Name 'cookietrigger' `
#                          -Trigger (New-PoshBotTrigger -Type 'Regex' -Trigger '(^| )cookies?( |$)') `
#                          -Description 'Likes cookies' `
#                          -ScriptBlock {
#                             '"Did somebody mention cookies? Om nom nom!"'
#                          }

# $c1, $c2 | % {
#     $plugin1 | Add-PoshBotPluginCommand -Command $_
# }
# $bot | Add-PoshBotPlugin -Plugin $plugin1

# Create a new plugin from a PowerShell module

$moduleName = 'demo'
$manifestPath = "$PSScriptRoot\Plugins\$moduleName\$($moduleName).psd1"
$bot | Add-PoshBotPlugin -ModuleManifest $manifestPath


# $demoPlugin =  New-PoshBotPlugin -Name 'demo'
# $manifestPath = "$PSScriptRoot\Plugins\$moduleName\$($moduleName).psd1"
# Import-Module -Name $manifestPath -Scope Local -Force
# $moduleCommands = Get-Command -Module $moduleName -CommandType Cmdlet, Function, Workflow
# foreach ($command in $moduleCommands) {
#     $cmdHelp = Get-Help -Name $command.Name
#     $cmdParams = @{
#         Name = $command.Name
#         Trigger = (New-PoshBotTrigger -Type 'Command' -Trigger $command.Name)
#         Description = $cmdHelp.Synopsis
#         HelpText = $cmdHelp.examples[0].example[0].code
#         CommandName = $command.Name
#         Module = $moduleName
#     }
#     $cmd = New-PoshBotCommand @cmdParams
#     $cmd.ManifestPath = $manifestPath
#     $cmd.FunctionInfo = $command

#     #$cmd.ModuleCommand = "$moduleName\$($command.Name)"
#     $demoPlugin.AddCommand($cmd)
# }
