
function Get-ScheduledCommand {
    <#
    .SYNOPSIS
        Get all scheduled commands.
    .PARAMETER Id
        The Id of the scheduled command to retrieve.
    .EXAMPLE
        !get-scheduledcommand

        List all scheduled commands
    .EXAMPLE !get-scheduledcommand --id e26b82cf473647e780041cee00a941de

        Get the scheduled command with Id [e26b82cf473647e780041cee00a941de]
    #>
    [PoshBot.BotCommand(
        Aliases = ('getschedule', 'get-schedule'),
        Permissions = 'manage-schedules'
    )]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [string]$Id
    )

    $fields = @(
        'Id',
        @{l='Command';e={$_.Message.Text}}
        @{l='Interval';e={"Every $($_.TimeValue) $($_.TimeInterval)"}}
        'TimesExecuted'
        @{l='StartAfter';e={$_.StartAfter.ToString('u')}}
        'Enabled'
    )

    if ($Id) {
        if ($schedule = $Bot.Scheduler.GetSchedule($Id)) {
            $msg = ($schedule | Select-Object -Property $fields | Format-List | Out-String).Trim()
            New-PoshBotTextResponse -Text $msg -AsCode
        } else {
            New-PoshBotCardResponse -Type Warning -Text "Scheduled command [$Id] not found." -ThumbnailUrl $thumb.warning
        }
    } else {
        $schedules = $Bot.Scheduler.ListSchedules()
        if ($schedules.Count -gt 0) {
            $msg = ($schedules | Select-Object -Property $fields | Format-Table -AutoSize | Out-String).Trim()
            New-PoshBotTextResponse -Text $msg -AsCode
        } else {
            New-PoshBotTextResponse -Text 'There are no commands scheduled'
        }
    }
}
