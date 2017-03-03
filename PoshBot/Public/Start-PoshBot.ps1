
function Start-PoshBot {
    [cmdletbinding(DefaultParameterSetName = 'bot')]
    param(
        [parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'bot')]
        [Alias('Bot')]
        [Bot]$InputObject,

        [parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'config')]
        [BotConfiguration]$Configuration,

        [parameter(Mandatory, ParameterSetName = 'path')]
        [string]$ConfigurationPath,

        [switch]$AsJob,

        [switch]$PassThru
    )

    process {
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
                $Configuration = Get-PoshBotConfiguration -Path $ConfigurationPath
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

                while($true) {
                    try {
                        $backend = New-PoshBotSlackBackend -Configuration $Configuration.BackendConfiguration
                        $bot = New-PoshBotInstance -Backend $backend -Configuration $Configuration
                        $bot.Start()
                    } catch {
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
    }
}
