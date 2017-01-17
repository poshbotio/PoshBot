
function Stop-Poshbot {
    <#
    .SYNOPSIS
        Stop a currently running PoshBot instance.
    .DESCRIPTION
        Stop a currently running PoshBot instance.
    .PARAMETER Id
        The Id of the bot to stop.
    .EXAMPLE
        Stop-PoshBot -Id 101

        Stop the bot instance with Id 101.

    .EXAMPLE
        Get-PoshBot | Stop-PoshBot

        Gets all running PoshBot instances and stops them.
    #>
    [cmdletbinding()]
    param(
        [parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int[]]$Id
    )

    begin {
        $remove = @()
    }

    process {
        foreach ($jobId in $Id) {
            if ($PSCmdlet.ShouldProcess($jobId, 'Stop PoshBot')) {
                $bot = $script:botTracker[$jobId]
                if ($bot) {

                    Write-Verbose -Message "Stopping PoshBot Id: $jobId"
                    Stop-Job -Id $jobId -Verbose:$false
                    Remove-Job -Id $JobId -Verbose:$false
                    $remove += $jobId
                } else {
                    throw "Unable to find PoshBot instance with Id [$Id]"
                }
            }
        }
    }

    end {
        # Remove this bot from tracking
        $remove | ForEach-Object {
            $script:botTracker.Remove($_)
        }
    }
}