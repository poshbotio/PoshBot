
function Get-PoshBot {
    <#
    .SYNOPSIS
        Gets any currently running instances of PoshBot that are running as background jobs.
    .DESCRIPTION
        PoshBot can be run in the background with PowerShell jobs. This function returns
        any currently running PoshBot instances.
    .PARAMETER Id
        One or more job IDs to retrieve.
    .EXAMPLE
        PS C:\> Get-PoshBot

        Id         : 5
        Name       : PoshBot_3ddfc676406d40fca149019d935f065d
        State      : Running
        InstanceId : 3ddfc676406d40fca149019d935f065d
        Config     : BotConfiguration

    .EXAMPLE
        PS C:\> Get-PoshBot -Id 100

        Id         : 100
        Name       : PoshBot_eab96f2ad147489b9f90e110e02ad805
        State      : Running
        InstanceId : eab96f2ad147489b9f90e110e02ad805
        Config     : BotConfiguration

        Gets the PoshBot job instance with ID 100.
    .INPUTS
		System.Int32
    .OUTPUTS
        PSCustomObject
    .LINK
        Start-PoshBot
    .LINK
        Stop-PoshBot
    #>
    [OutputType([PSCustomObject])]
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
