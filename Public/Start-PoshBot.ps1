
function Start-PoshBot {
    [cmdletbinding(DefaultParameterSetName = 'bot')]
    param(
        [parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'bot')]
        [Alias('Bot')]
        [Bot]$InputObject,

        [parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'config')]
        [BotConfiguration]$Configuration,

        [parameter(Mandatory, ParameterSetName = 'configpath')]
        [string]$ConfigurationPath,

        [parameter(ParameterSetName = 'configpath')]
        [switch]$AsJob,

        [parameter(ParameterSetName = 'configpath')]
        [switch]$PassThru
    )

    process {

        switch ($PSCmdlet.ParameterSetName) {
            'bot' {
                $InputObject.Start()
            }
            'config' {
                $backend = New-PoshBotSlackBackend -Name 'SlackBackend' -BotToken $env:SLACK_TOKEN
                $bot = New-PoshBotInstance -Backend $backend -Configuration $Configuration
                $bot.Start()
            }
            'configpath' {
                $sb = {
                    param(
                        $ConfigPath
                    )

                    $backend = New-PoshBotSlackBackend -Name 'SlackBackend' -BotToken $env:SLACK_TOKEN
                    $bot = New-PoshBotInstance -Name 'SlackBot' -Backend $backend -ConfigurationPath $ConfigPath
                    $bot.Start()
                }

                if ($PSBoundParameters.ContainsKey('AsJob')) {
                    $instanceId = (New-Guid).ToString().Replace('-', '')
                    $jobName = "PoshBot_$instanceId"
                    $job = Start-Job -ScriptBlock $sb -Name $jobName -ArgumentList $ConfigurationPath
                    $config = Get-PoshBotConfiguration -Path $ConfigurationPath

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
                    & $sb $ConfigurationPath
                }
            }
        }
    }
}
