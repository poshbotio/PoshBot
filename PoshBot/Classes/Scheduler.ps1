
class Scheduler : BaseLogger {

    [hashtable]$Schedules = @{}

    hidden [StorageProvider]$_Storage

    Scheduler([StorageProvider]$Storage, [Logger]$Logger) {
        $this._Storage = $Storage
        $this.Logger = $Logger
        $this.Initialize()
    }

    [void]Initialize() {
        $this.LogInfo('Initializing')
        $this.LoadState()
    }

    [void]LoadState() {
        $this.LogVerbose('Loading scheduler state from storage')

        if ($scheduleConfig = $this._Storage.GetConfig('schedules')) {
            foreach($key in $scheduleConfig.Keys) {
                $sched = $scheduleConfig[$key]
                $msg = [Message]::new()
                $msg.Id = $sched.Message.Id
                $msg.Text = $sched.Message.Text
                $msg.To = $sched.Message.To
                $msg.From = $sched.Message.From
                $msg.Type = $sched.Message.Type
                $msg.Subtype = $sched.Message.Subtype
                if ($sched.Once) {
                    $newSchedule = [ScheduledMessage]::new($msg, $sched.StartAfter.ToUniversalTime())
                } else {
                    if (-not [string]::IsNullOrEmpty($sched.StartAfter)) {
                        $newSchedule = [ScheduledMessage]::new($sched.TimeInterval, $sched.TimeValue, $msg, $sched.Enabled, $sched.StartAfter.ToUniversalTime())

                        if ($newSchedule.StartAfter -lt (Get-Date).ToUniversalTime()) {
                            #Prevent reruns of commands initially scheduled at least one interval ago
                            $newSchedule.RecalculateStartAfter()
                        }
                    } else {
                        $newSchedule = [ScheduledMessage]::new($sched.TimeInterval, $sched.TimeValue, $msg, $sched.Enabled, (Get-Date).ToUniversalTime())
                    }
                }

                $newSchedule.Id = $sched.Id
                $this.ScheduleMessage($newSchedule, $false)
            }
            $this.SaveState()
        }
    }

    [void]SaveState() {
        $this.LogVerbose('Saving scheduler state to storage')

        $schedulesToSave = @{}
        foreach ($schedule in $this.Schedules.GetEnumerator()) {
            $schedulesToSave.Add("sched_$($schedule.Name)", $schedule.Value.ToHash())
        }
        $this._Storage.SaveConfig('schedules', $schedulesToSave)
    }

    [void]ScheduleMessage([ScheduledMessage]$ScheduledMessage) {
        $this.ScheduleMessage($ScheduledMessage, $true)
    }

    [void]ScheduleMessage([ScheduledMessage]$ScheduledMessage, [bool]$Save) {
        if (-not $this.Schedules.ContainsKey($ScheduledMessage.Id)) {
            $this.LogInfo("Scheduled message [$($ScheduledMessage.Id)]", $ScheduledMessage)
            $this.Schedules.Add($ScheduledMessage.Id, $ScheduledMessage)
        } else {
            $msg = "Id [$($ScheduledMessage.Id)] is already scheduled"
            $this.LogInfo([LogSeverity]::Error, $msg)
        }
        if ($Save) {
            $this.SaveState()
        }
    }

    [void]RemoveScheduledMessage([string]$Id) {
        if ($this.GetSchedule($Id)) {
            $this.Schedules.Remove($id)
            $this.LogInfo("Scheduled message [$($_.Id)] removed")
            $this.SaveState()
        }
    }

    [ScheduledMessage[]]ListSchedules() {
        $result = $this.Schedules.GetEnumerator() |
            Select-Object -ExpandProperty Value |
            Sort-Object -Property TimeValue -Descending

        return $result
    }

    [Message[]]GetTriggeredMessages() {
        $remove = @()
        $messages = $this.Schedules.GetEnumerator() | Foreach-Object {
            if ($_.Value.HasElapsed()) {
                $this.LogInfo("Timer reached on scheduled command [$($_.Value.Id)]")

                # Check if one time command
                if ($_.Value.Once) {
                    $remove += $_.Value.Id
                } else {
                    $_.Value.RecalculateStartAfter()
                }

                $newMsg = $_.Value.Message.Clone()
                $newMsg.Time = Get-Date
                $newMsg
            }
        }

        # Remove any one time commands that have triggered
        foreach ($id in $remove) {
            $this.RemoveScheduledMessage($id)
        }

        return $messages
    }

    [ScheduledMessage]GetSchedule([string]$Id) {
        if ($msg = $this.Schedules[$id]) {
            return $msg
        } else {
            $msg = "Unknown schedule Id [$Id]"
            $this.LogInfo([LogSeverity]::Warning, $msg)
            return $null
        }
    }

    [ScheduledMessage]SetSchedule([ScheduledMessage]$ScheduledMessage) {
        $existingMessage = $this.GetSchedule($ScheduledMessage.Id)
        $existingMessage.Init($ScheduledMessage.TimeInterval, $ScheduledMessage.TimeValue, $ScheduledMessage.Message, $ScheduledMessage.Enabled, $ScheduledMessage.StartAfter)
        $this.LogInfo("Scheduled message [$($ScheduledMessage.Id)] modified", $existingMessage)

        $this.SaveState()
        return $existingMessage
    }

    [ScheduledMessage]EnableSchedule([string]$Id) {
        if ($msg = $this.GetSchedule($Id)) {
            $this.LogInfo("Enabled scheduled command [$($_.Id)] enabled")
            $msg.Enable()
            $this.SaveState()
            return $msg
        } else {
            return $null
        }
    }

    [ScheduledMessage]DisableSchedule([string]$Id) {
        if ($msg = $this.GetSchedule($Id)) {
            $this.LogInfo("Disabled scheduled command [$($_.Id)] enabled")
            $msg.Disable()
            $this.SaveState()
            return $msg
        } else {
            return $null
        }
    }
}
