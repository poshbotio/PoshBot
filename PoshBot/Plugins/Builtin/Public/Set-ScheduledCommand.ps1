
function Set-ScheduledCommand {
    <#
    .SYNOPSIS
        Modify a scheduled command.
    .PARAMETER Id
        The Id of the scheduled command to edit.
    .PARAMETER Value
        Execute the command after the specified number of intervals (e.g., 2 hours).
    .PARAMETER Inteval
        The interval in which to schedule the command. The valid values are 'days', 'hours', 'minutes', and 'seconds'.
    .PARAMETER StartAfter
        Start the scheduled command exeuction after this date/time.
    .EXAMPLE
        !set-scheduledcommand --id e26b82cf473647e780041cee00a941de --value 2 --interval days

        Edit the existing scheduled command with Id [e26b82cf473647e780041cee00a941de] and set the
        repetition interval to every 2 days.
    .EXAMPLE
        !set-scheduledcommand --id ccef0790b94542a685e78b4ec50c8c1e --value 1 --interval hours --startafter '10:00pm'

        Edit the existing scheduled command with Id [ccef0790b94542a685e78b4ec50c8c1e] and set the
        repition interval to every hours starting at 10:00pm.
    #>
    [PoshBot.BotCommand(
        Aliases = ('setschedule', 'set-schedule'),
        Permissions = 'manage-schedules'
    )]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Mandatory, Position = 0)]
        [string]$Id,

        [parameter(Mandatory, Position = 1)]
        [ValidateNotNull()]
        [int]$Value,

        [parameter(Mandatory, Position = 2)]
        [ValidateSet('days', 'hours', 'minutes', 'seconds')]
        [ValidateNotNullOrEmpty()]
        [string]$Interval,

        [ValidateScript({
            if ($_ -as [datetime]) {
                return $true
            } else {
                throw '''StartAfter'' must be a datetime.'
            }
        })]
        [string]$StartAfter
    )

    if ($scheduledMessage = $Bot.Scheduler.GetSchedule($Id)) {
        $scheduledMessage.TimeInterval = $Interval
        $scheduledMessage.TimeValue = $Value
        if ($PSBoundParameters.ContainsKey('StartAfter')) {
            $scheduledMessage.StartAfter = [datetime]$StartAfter
        }
        $scheduledMessage = $bot.Scheduler.SetSchedule($scheduledMessage)
        New-PoshBotCardResponse -Type Normal -Text "Schedule for command [$($scheduledMessage.Message.Text)] changed to every [$Value $($Interval.ToLower())]." -ThumbnailUrl $thumb.success
    } else {
        New-PoshBotCardResponse -Type Warning -Text "Scheduled command [$Id] not found." -ThumbnailUrl $thumb.warning
    }
}
