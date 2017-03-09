
function New-PoshBotInstance {
    <#
    .SYNOPSIS
        Creates a new instance of PoshBot
    .DESCRIPTION
        Creates a new instance of PoshBot from an existing configuration (.psd1) file or a configuration object.
    .PARAMETER Configuration
        The bot configuration object to create a new instance from.
    .PARAMETER Path
        The path to a PowerShell data (.psd1) file to create a new instance from.
    .PARAMETER Backend
        The backend object that hosts logic for receiving and sending messages to a chat network.
    .EXAMPLE
        PS C:\> New-PoshBotInstance -Path 'C:\Users\joeuser\.poshbot\Cherry2000.psd1' -Backend $backend

        Name          : Cherry2000
        Backend       : SlackBackend
        Storage       : StorageProvider
        PluginManager : PluginManager
        RoleManager   : RoleManager
        Executor      : CommandExecutor
        MessageQueue  : {}
        Configuration : BotConfiguration

        Create a new PoshBot instance from configuration file [C:\Users\joeuser\.poshbot\Cherry2000.psd1] and Slack backend object [$backend].
    .EXAMPLE
        PS C:\> $botConfig = Get-PoshBotConfiguration -Path (Join-Path -Path $env:USERPROFILE -ChildPath '.poshbot\Cherry2000.psd1')
        PS C:\> $backend = New-PoshBotSlackBackend -Configuration $botConfig.BackendConfiguration
        PS C:\> $myBot = $botConfig | New-PoshBotInstance -Backend $backend
        PS C:\> $myBot | Format-List

        Name          : Cherry2000
        Backend       : SlackBackend
        Storage       : StorageProvider
        PluginManager : PluginManager
        RoleManager   : RoleManager
        Executor      : CommandExecutor
        MessageQueue  : {}
        Configuration : BotConfiguration

        Gets a bot configuration from the filesytem, creates a chat backend object, and then creates a new bot instance.
    .EXAMPLE
        PS C:\> $botConfig = Get-PoshBotConfiguration -Path (Join-Path -Path $env:USERPROFILE -ChildPath '.poshbot\Cherry2000.psd1')
        PS C:\> $backend = $botConfig | New-PoshBotSlackBackend
        PS C:\> $myBotJob = $botConfig | New-PoshBotInstance -Backend $backend | Start-PoshBot -AsJob -PassThru

        Gets a bot configuration, creates a Slack backend from it, then creates a new PoshBot instance and starts it as a background job.
    .INPUTS
		String
    .INPUTS
		BotConfiguration
    .OUTPUTS
        Bot
    .LINK
        Get-PoshBotConfiguration
    .LINK
        New-PoshBotSlackBackend
    .LINK
        Start-PoshBot
    #>
    [cmdletbinding(DefaultParameterSetName = 'path')]
    param(
        [parameter(Mandatory, ParameterSetName = 'path', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateScript({
            if (Test-Path -Path $_) {
                if ( (Get-Item -Path $_).Extension -eq '.psd1') {
                    $true
                } else {
                    Throw 'Path must be to a valid .psd1 file'
                }
            } else {
                Throw 'Path is not valid'
            }
        })]
        [string[]]$Path = (Join-Path -Path (Join-Path -Path $env:USERPROFILE -ChildPath '.poshbot') -ChildPath 'PoshBot.psd1'),

        [parameter(Mandatory, ParameterSetName = 'config', ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [BotConfiguration[]]$Configuration,

        [parameter(Mandatory)]
        [Backend]$Backend
    )

    begin {
        $here = $script:moduleRoot
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq 'path') {
            $Configuration = @()
            foreach ($item in $Path) {
                $Configuration += Get-PoshBotConfiguration -Path $item
            }
        }

        foreach ($config in $Configuration) {
            Write-Verbose -Message "Creating bot instance with name [$($config.Name)"
            [Bot]::new($Backend, $here, $config)
        }
    }
}
