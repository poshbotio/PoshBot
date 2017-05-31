
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
    .PARAMETER LiteralPath
        Specifies the path(s) to the current location of the file(s). Unlike the Path parameter, the value of LiteralPath is used exactly as it is typed.
        No characters are interpreted as wildcards. If the path includes escape characters, enclose it in single quotation marks. Single quotation
        marks tell PowerShell not to interpret any characters as escape sequences.
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
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope='Function', Target='*')]
    [cmdletbinding(DefaultParameterSetName = 'path')]
    param(
        [parameter(
            Mandatory,
            ParameterSetName  = 'Path',
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [string[]]$Path,

        [parameter(
            Mandatory,
            ParameterSetName = 'LiteralPath',
            Position = 0,
            ValueFromPipelineByPropertyName
        )]
        [ValidateNotNullOrEmpty()]
        [Alias('PSPath')]
        [string[]]$LiteralPath,

        [parameter(
            Mandatory,
            ParameterSetName = 'config',
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [BotConfiguration[]]$Configuration,

        [parameter(Mandatory)]
        [Backend]$Backend
    )

    begin {
        $here = $PSScriptRoot
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq 'path' -or $PSCmdlet.ParameterSetName -eq 'LiteralPath') {
            # Resolve path(s)
            if ($PSCmdlet.ParameterSetName -eq 'Path') {
                $paths = Resolve-Path -Path $Path | Select-Object -ExpandProperty Path
            } elseif ($PSCmdlet.ParameterSetName -eq 'LiteralPath') {
                $paths = Resolve-Path -LiteralPath $LiteralPath | Select-Object -ExpandProperty Path
            }

            $Configuration = @()
            foreach ($item in $paths) {
                if (Test-Path $item) {
                    if ( (Get-Item -Path $item).Extension -eq '.psd1') {
                        $Configuration += Get-PoshBotConfiguration -Path $item
                    } else {
                        Throw 'Path must be to a valid .psd1 file'
                    }
                } else {
                    Write-Error -Message "Path [$item] is not valid."
                }
            }
        }

        foreach ($config in $Configuration) {
            Write-Verbose -Message "Creating bot instance with name [$($config.Name)]"
            [Bot]::new($Backend, $here, $config)
        }
    }
}

Export-ModuleMember -Function 'New-PoshBotInstance'
