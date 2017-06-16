
function Remove-ScheduledCommand {
    <#
    .SYNOPSIS
        Remove a scheduled command.
    .PARAMETER Id
        The Id of the scheduled command to remove.
    .EXAMPLE
        !remove-scheduledcommand --id 1fb032bdec82423ba763227c83ca2c89

        Remove the scheduled command with id [1fb032bdec82423ba763227c83ca2c89].
    #>
    [PoshBot.BotCommand(
        Aliases = ('removeschedule', 'remove-schedule'),
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
        $Bot.Scheduler.RemoveScheduledMessage($Id)
        $msg = "Schedule Id [$Id] removed"
        New-PoshBotCardResponse -Type Normal -Text $msg -ThumbnailUrl $thumb.success
    } else {
        New-PoshBotCardResponse -Type Warning -Text "Scheduled command [$Id] not found." -ThumbnailUrl $thumb.warning
    }
}
