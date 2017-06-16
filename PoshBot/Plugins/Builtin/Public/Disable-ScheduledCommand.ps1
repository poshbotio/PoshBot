
function Disable-ScheduledCommand {
    <#
    .SYNOPSIS
        Disable a scheduled command.
    .PARAMETER Id
        The Id of the scheduled command to disable.
    .EXAMPLE
        !disable-scheduledcommand --id 2979f9961a0c4dea9fa6ea073a281e35

        Disable the scheduled command with id [2979f9961a0c4dea9fa6ea073a281e35].
    #>
    [PoshBot.BotCommand(
        Aliases = 'disableschedule',
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
        $scheduledMessage = $Bot.Scheduler.DisableSchedule($Id)
        $fields = @(
            'Id'
            @{l='Command'; e = {$_.Message.Text}}
            @{l='Interval'; e = {$_.TimeInterval}}
            @{l='Value'; e = {$_.TimeValue}}
            'TimesExecuted'
            @{l='StartAfter';e={_.StartAfter.ToString('s')}}
            'Enabled'
        )
        $msg =  "Schedule for command [$($scheduledMessage.Message.Text)] disabled`n"
        $msg += ($scheduledMessage | Select-Object -Property $fields | Format-List | Out-String).Trim()
        New-PoshBotCardResponse -Type Normal -Text $msg -ThumbnailUrl $thumb.success
    } else {
        New-PoshBotCardResponse -Type Warning -Text "Scheduled command [$Id] not found." -ThumbnailUrl $thumb.warning
    }
}
