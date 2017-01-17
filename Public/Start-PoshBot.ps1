
function Start-PoshBot {
    [cmdletbinding()]
    param(
        [parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'bot')]
        [Alias('Bot')]
        [Bot]$InputObject,

        [parameter(Mandatory, ParameterSetName = 'config')]
        [string]$ConfigurationDirectory,

        [parameter(ParameterSetName = 'config')]
        [switch]$AsJob,

        [parameter(ParameterSetName = 'config')]
        [switch]$PassThru
    )

    process {
        if ($PSCmdlet.ParameterSetName -eq 'bot') {
            $InputObject.Start()
        } elseif ($PSCmdlet.ParameterSetName -eq 'config') {
            $sb = {
                param(
                    $Dir
                )

                $backend = New-PoshBotSlackBackend -Name 'SlackBackend' -BotToken $env:SLACK_TOKEN
                $bot = New-PoshBotInstance -Name 'SlackBot' -Backend $backend -ConfigurationDirectory $Dir
                $bot.Start()
            }

            if ($PSBoundParameters.ContainsKey('AsJob')) {
                $instanceId = (New-Guid).ToString().Replace('-', '')
                $jobName = "PoshBot_$instanceId"
                $job = Start-Job -ScriptBlock $sb -Name $jobName -ArgumentList $ConfigurationDirectory
                $config = Get-PoshBotConfiguration -Path (Join-Path -Path $ConfigurationDirectory -ChildPath 'PoshBot.psd1')

                # Track the bot instance
                $botTracker = @{
                    JobId = $job.Id
                    Name = $jobName
                    InstanceId = $instanceId
                    Config = $config
                }
                $script:botTracker.Add($job.Id, $botTracker)

                if ($PSBoundParameters.ContainsKey('PassThru')) {
                    Get-PoshBot -Id $job.Id
                }
            } else {
                & $sb $ConfigurationDirectory
            }
        }
    }
}
