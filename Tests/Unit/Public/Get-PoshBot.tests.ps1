
InModuleScope PoshBot {
    describe 'Get-PoshBot' {

        $script:botTracker = @{}

        it 'Returns nothing if no jobs exist' {
            Get-Poshbot | Should BeNullorEmpty
        }

        # Create a fake PoshBot job tracker instance
        $guid1 = (New-Guid).ToString()
        $guid2 = (New-Guid).ToString()
        $script:botTracker.Add(1, @{
            JobId = 1
            Name = "PoshBot_$guid1"
            State = 'Running'
            InstanceId = $guid1
            Config = [BotConfiguration]::new()
        })
        $script:botTracker.Add(2, @{
            JobId = 1
            Name = "PoshBot_$guid2"
            State = 'Running'
            InstanceId = $guid2
            Config = [BotConfiguration]::new()
        })

        # No jobs are actually running so fake it until we make it
        mock Get-Job { return 'Running' }

        it 'Returns all running job instances' {
            $j = Get-PoshBot
            $j.Count | should be 2
        }

        it 'Returns a specific job instance' {
            $j = Get-PoshBot -Id 1
            $j | should not benullorempty
            $j.Id | should be 1
        }

        it 'Accepts job IDs from the pipeline' {
            $j = 1, 2 | Get-PoshBot
            $j.Count | should be 2
        }
    }
}
