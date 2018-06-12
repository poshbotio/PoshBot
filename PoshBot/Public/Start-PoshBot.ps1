
function Start-PoshBot {
    <#
    .SYNOPSIS
        Starts a new instance of PoshBot interactively or in a job.
    .DESCRIPTION
        Starts a new instance of PoshBot interactively or in a job.
    .PARAMETER InputObject
        An existing PoshBot instance to start.
    .PARAMETER Configuration
        A PoshBot configuration object to use to start the bot instance.
    .PARAMETER Path
        The path to a PoshBot configuration file.
        A new instance of PoshBot will be created from this file.
    .PARAMETER AsJob
        Run the PoshBot instance in a background job.
    .PARAMETER PassThru
        Return the PoshBot instance Id that is running as a job.
    .EXAMPLE
        PS C:\> Start-PoshBot -Bot $bot

        Runs an instance of PoshBot that has already been created interactively in the shell.
    .EXAMPLE
        PS C:\> $bot | Start-PoshBot -Verbose

        Runs an instance of PoshBot that has already been created interactively in the shell.
    .EXAMPLE
        PS C:\> $config = Get-PoshBotConfiguration -Path (Join-Path -Path $env:USERPROFILE -ChildPath '.poshbot\MyPoshBot.psd1')
        PS C:\> Start-PoshBot -Config $config

        Gets a PoshBot configuration from file and starts the bot interactively.
    .EXAMPLE
        PS C:\> Get-PoshBot -Id 100

        Id         : 100
        Name       : PoshBot_eab96f2ad147489b9f90e110e02ad805
        State      : Running
        InstanceId : eab96f2ad147489b9f90e110e02ad805
        Config     : BotConfiguration

        Gets the PoshBot job instance with ID 100.
    .INPUTS
        Bot
    .INPUTS
        BotConfiguration
    .INPUTS
        String
    .OUTPUTS
        PSCustomObject
    .LINK
        Start-PoshBot
    .LINK
        Stop-PoshBot
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope='Function', Target='*')]
    [cmdletbinding(DefaultParameterSetName = 'bot')]
    param(
        [parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'bot')]
        [Alias('Bot')]
        [Bot]$InputObject,

        [parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'config')]
        [BotConfiguration]$Configuration,

        [parameter(Mandatory, ParameterSetName = 'path')]
        [string]$Path,

        [switch]$AsJob,

        [switch]$PassThru
    )

    process {
        try {
            switch ($PSCmdlet.ParameterSetName) {
                'bot' {
                    $bot = $InputObject
                    $Configuration = $bot.Configuration
                }
                'config' {
                    $backend = New-PoshBotSlackBackend -Configuration $Configuration.BackendConfiguration
                    $bot = New-PoshBotInstance -Backend $backend -Configuration $Configuration
                }
                'path' {
                    $Configuration = Get-PoshBotConfiguration -Path $Path
                    $backend = New-PoshBotSlackBackend -Configuration $Configuration.BackendConfiguration
                    $bot = New-PoshBotInstance -Backend $backend -Configuration $Configuration
                }
            }

            if ($AsJob) {
                $sb = {
                    param(
                        [parameter(Mandatory)]
                        $Configuration
                    )

                    Import-Module PoshBot -ErrorAction Stop

                    $tempConfig = New-PoshBotConfiguration
                    $realConfig = $tempConfig.SerializeInstance($Configuration)

                    while($true) {
                        try {
                            $backend = New-PoshBotSlackBackend -Configuration $realConfig.BackendConfiguration
                            $bot = New-PoshBotInstance -Backend $backend -Configuration $realConfig
                            $bot.Start()
                        } catch {
                            Write-Error $_
                            Write-Error 'PoshBot crashed :( Restarting...'
                            Start-Sleep -Seconds 5
                        }
                    }
                }

                $instanceId = (New-Guid).ToString().Replace('-', '')
                $jobName = "PoshBot_$instanceId"

                #$job = Invoke-Command -ScriptBlock $sb -JobName $jobName -ArgumentList $bot -AsJob
                $job = Start-Job -ScriptBlock $sb -Name $jobName -ArgumentList $Configuration

                # Track the bot instance
                $botTracker = @{
                    JobId = $job.Id
                    Name = $jobName
                    InstanceId = $instanceId
                    Config = $Configuration
                }
                $script:botTracker.Add($job.Id, $botTracker)

                if ($PSBoundParameters.ContainsKey('PassThru')) {
                    Get-PoshBot -Id $job.Id
                }
            } else {
                $bot.Start()
            }
        } catch {
            throw $_
        }
        finally {
            if (-not $AsJob) {
                # We're here because CTRL+C was entered.
                # Make sure to disconnect the bot from the backend chat network
                if ($bot) {
                    Write-Verbose -Message 'Stopping PoshBot'
                    $bot.Disconnect()
                }
            }
        }
    }
}

Export-ModuleMember -Function 'Start-Poshbot'
