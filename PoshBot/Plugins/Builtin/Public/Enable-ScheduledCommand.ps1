
function Enable-ScheduledCommand {
    <#
    .SYNOPSIS
        Enable a scheduled command.
    .PARAMETER Id
        The Id of the scheduled command to enable.
    .EXAMPLE
        !enable-scheduledcommand --id a993c0880b184de098f46d8bbc81436b

        Enable the scheduled command with id [a993c0880b184de098f46d8bbc81436b].
    #>
    [PoshBot.BotCommand(
        Aliases = ('enableschedule', 'enable-schedule'),
        Permissions = 'manage-schedules'
    )]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Id
    )

    if ($Bot.Scheduler.GetSchedule($Id)) {
        $scheduledMessage = $Bot.Scheduler.EnableSchedule($Id)
        $fields = @(
            'Id'
            @{l='Command'; e = {$_.Message.Text}}
            @{l='Interval'; e = {$_.TimeInterval}}
            @{l='Value'; e = {$_.TimeValue}}
            'TimesExecuted'
            @{l='StartAfter';e={_.StartAfter.ToString('s')}}
            'Enabled'
        )
        $msg = "Schedule for command [$($scheduledMessage.Message.Text)] enabled`n"
        $msg += ($scheduledMessage | Select-Object -Property $fields | Format-List | Out-String).Trim()
        New-PoshBotCardResponse -Type Normal -Text $msg -ThumbnailUrl $thumb.success
    } else {
        New-PoshBotCardResponse -Type Warning -Text "Scheduled command [$Id] not found." -ThumbnailUrl $thumb.warning
    }
}
