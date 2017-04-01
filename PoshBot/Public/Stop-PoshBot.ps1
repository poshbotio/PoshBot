
function Stop-Poshbot {
    <#
    .SYNOPSIS
        Stop a currently running PoshBot instance that is running as a background job.
    .DESCRIPTION
        PoshBot can be run in the background with PowerShell jobs. This function stops
        a currently running PoshBot instance.
    .PARAMETER Id
        The job Id of the bot to stop.
    .PARAMETER Force
        Stop PoshBot instance without prompt
    .EXAMPLE
        Stop-PoshBot -Id 101

        Stop the bot instance with Id 101.
    .EXAMPLE
        Get-PoshBot | Stop-PoshBot

        Gets all running PoshBot instances and stops them.
    .INPUTS
		System.Int32
    .LINK
        Get-PoshBot
    .LINK
        Start-PoshBot
    #>
    [cmdletbinding(SupportsShouldProcess, ConfirmImpact = 'high')]
    param(
        [parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [int[]]$Id,

        [switch]$Force
    )

    begin {
        $remove = @()
    }

    process {
        foreach ($jobId in $Id) {
            if ($Force -or $PSCmdlet.ShouldProcess($jobId, 'Stop PoshBot')) {
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

Export-ModuleMember -Function 'Stop-Poshbot'
