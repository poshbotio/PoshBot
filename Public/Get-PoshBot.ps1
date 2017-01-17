
function Get-PoshBot {
    [cmdletbinding()]
    param(
        [parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int[]]$Id = @()
    )

    process {
        if ($Id.Count -gt 0) {
            foreach ($item in $Id) {
                if ($b = $script:botTracker.$item) {
                    [pscustomobject][ordered]@{
                        Id = $item
                        Name = $b.Name
                        State = (Get-Job -Id $b.jobId).State
                        InstanceId = $b.InstanceId
                        Config = $b.Config
                    }
                }
            }
        } else {
            $script:botTracker.GetEnumerator() | ForEach-Object {
                [pscustomobject][ordered]@{
                    Id = $_.Value.JobId
                    Name = $_.Value.Name
                    State = (Get-Job -Id $_.Value.JobId).State
                    InstanceId = $_.Value.InstanceId
                    Config = $_.Value.Config
                }
            }
        }
    }
}
