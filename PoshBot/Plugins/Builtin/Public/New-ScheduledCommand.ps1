
function New-ScheduledCommand {
    <#
    .SYNOPSIS
        Create a new scheduled command.
    .PARAMETER Command
        The command string to schedule. This will be in the form of '!foo --bar baz' just like you would
        type interactively.
    .PARAMETER Value
        Execute the command after the specified number of intervals (e.g., 2 hours).
    .PARAMETER Interval
        The interval in which to schedule the command. The valid values are 'days', 'hours', 'minutes', and 'seconds'.
    .PARAMETER StartAfter
        Start the scheduled command exeuction after this date/time.
    .PARAMETER Once
        Execute the scheduled command once and then remove the schedule.
        This parameter is not valid with the Interval and Value parameters.
    .EXAMPLE
        !new-scheduledcommand --command 'status' --interval hours --value 4

        Execute the [status] command every 4 hours.
    .EXAMPLE
        !new-scheduledcommand --command !myplugin:motd' --interval days --value 1 --startafter '8:00am'

        Execute the command [myplugin:motd] every day starting at 8:00am.
    .EXAMPLE
        !new-scheduledcommand --command "!myplugin:restart-server --computername frodo --startafter '2016/07/04 6:00pm'" --once

        Execute the command [restart-server] on computername [frodo] at 6:00pm on 2016/07/04.
    #>
    [PoshBot.BotCommand(
        Aliases = ('newschedule', 'new-schedule'),
        Permissions = 'manage-schedules'
    )]
    [cmdletbinding(DefaultParameterSetName = 'repeat')]
    param(
        [parameter(Mandatory, ParameterSetName = 'repeat')]
        [parameter(Mandatory, ParameterSetName = 'once')]
        $Bot,

        [parameter(Mandatory, Position = 0, ParameterSetName = 'repeat')]
        [parameter(Mandatory, Position = 0, ParameterSetName = 'once')]
        [ValidateNotNullOrEmpty()]
        [string]$Command,

        [parameter(Mandatory, Position = 1, ParameterSetName = 'repeat')]
        [ValidateNotNull()]
        [int]$Value,

        [parameter(Mandatory, Position = 2, ParameterSetName = 'repeat')]
        [ValidateSet('days', 'hours', 'minutes', 'seconds')]
        [ValidateNotNullOrEmpty()]
        [string]$Interval,

        [parameter(ParameterSetName = 'repeat')]
        [parameter(Mandatory, ParameterSetName = 'once')]
        [ValidateScript({
            if ($_ -as [datetime]) {
                return $true
            } else {
                throw '''StartAfter'' must be a datetime.'
            }
        })]
        [string]$StartAfter,

        [parameter(Mandatory, ParameterSetName = 'once')]
        [switch]$Once
    )

    if (-not $Command.StartsWith($Bot.Configuration.CommandPrefix)) {
        $Command = $Command.Insert(0, $Bot.Configuration.CommandPrefix)
    }

    $botMsg            = [Message]::new()
    $botMsg.Text       = $Command
    $botMsg.From       = $global:PoshBotContext.From
    $botMsg.To         = $global:PoshBotContext.To
    $botMsg.RawMessage = $global:PoshBotContext.OriginalMessage.RawMessage

    if ($PSCmdlet.ParameterSetName -eq 'repeat') {
        # This command will be executed on a schedule with an optional time to start the interval
        if ($PSBoundParameters.ContainsKey('StartAfter')) {
            $schedMsg = [ScheduledMessage]::new($Interval, $value, $botMsg, [datetime]$StartAfter)
        } else {
            $schedMsg = [ScheduledMessage]::new($Interval, $value, $botMsg)
        }
    } elseIf ($PSCmdlet.ParameterSetName -eq 'once') {
        # This command will be executed once then removed from the scheduler
        $schedMsg = [ScheduledMessage]::new($botMsg, [datetime]$StartAfter)
    }

    try {
        $Bot.Scheduler.ScheduleMessage($schedMsg)

        if ($PSCmdlet.ParameterSetName -eq 'repeat') {
            New-PoshBotCardResponse -Type Normal -Text "Command [$Command] with ID [$($schedMsg.Id)] scheduled at interval [$Value $($Interval.ToLower())]." -ThumbnailUrl $thumb.success
        } elseIf ($PSCmdlet.ParameterSetName -eq 'once') {
            New-PoshBotCardResponse -Type Normal -Text "Command [$Command] with ID [$($schedMsg.Id)] scheduled for one time at [$([datetime]$StartAfter)]." -ThumbnailUrl $thumb.success
        }
    } catch {
        New-PoshBotCardResponse -Type Error -Text $_.ToString() -ThumbnailUrl $thumb.error
    }
}
