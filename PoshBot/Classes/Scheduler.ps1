
class Scheduler {

    [hashtable]$Schedules = @{}

    hidden [StorageProvider]$_Storage

    hidden [Logger]$_Logger

    Scheduler([StorageProvider]$Storage, [Logger]$Logger) {
        $this._Storage = $Storage
        $this._Logger = $Logger
        $this.Initialize()
    }

    [void]Initialize() {
        $this._Logger.Info([LogMessage]::new('[Scheduler:Initialize] Initializing'))
        $this.LoadState()
    }

    [void]LoadState() {
        $this._Logger.Verbose([LogMessage]::new('[Scheduler:LoadState] Loading scheduler state from storage'))

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
                $newSchedule = [ScheduledMessage]::new($sched.TimeInterval, $sched.TimeValue, $msg, $sched.Enabled)
                $newSchedule.Id = $sched.Id
                $this.ScheduleMessage($newSchedule, $false)
            }
            $this.SaveState()
        }
    }

    [void]SaveState() {
        $this._Logger.Verbose([LogMessage]::new('[Scheduler:SaveState] Saving scheduler state to storage'))

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
            $this._Logger.Info([LogMessage]::new("[Scheduler:ScheduleMessage] Scheduled message [$($ScheduledMessage.Id)]", $ScheduledMessage))
            if ($ScheduledMessage.Enabled) {
                $ScheduledMessage.StartTimer()
            }
            $this.Schedules.Add($ScheduledMessage.Id, $ScheduledMessage)
        } else {
            $msg = "[Scheduler:ScheduleMessage] Id [$($ScheduledMessage.Id)] is already scheduled"
            $this._Logger.Info([LogMessage]::new([LogSeverity]::Error, $msg))
            Write-Error -Message $msg
        }
        if ($Save) {
            $this.SaveState()
        }
    }

    [void]RemoveScheduledMessage([string]$Id) {
        if ($this.GetSchedule($Id)) {
            $this.Schedules.Remove($id)
            $this._Logger.Info([LogMessage]::new("[Scheduler:RemoveScheduledMessage] Scheduled message [$($_.Id)] removed"))
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
        $messages = $this.Schedules.GetEnumerator() | Foreach-Object {
            if ($_.Value.HasElapsed()) {
                $this._Logger.Info([LogMessage]::new("[Scheduler:GetTriggeredMessages] Timer reached on scheduled command [$($_.Value.Id)]"))
                $_.Value.ResetTimer()
                $newMsg = $_.Value.Message.Clone()
                $newMsg.Time = Get-Date
                $newMsg
            }
        }
        return $messages
    }

    [ScheduledMessage]GetSchedule([string]$Id) {
        if ($msg = $this.Schedules[$id]) {
            return $msg
        } else {
            $msg = "[Scheduler:GetSchedule] Unknown schedule Id [$Id]"
            $this._Logger.Info([LogMessage]::new([LogSeverity]::Error, $msg))
            Write-Error -Message $msg
            return $null
        }
    }

    [ScheduledMessage]SetSchedule([ScheduledMessage]$ScheduledMessage) {
        $existingMessage = $this.GetSchedule($ScheduledMessage.Id)
        $existingMessage.Init($ScheduledMessage.TimeInterval, $ScheduledMessage.TimeValue, $ScheduledMessage.Message, $ScheduledMessage.Enabled)
        $this._Logger.Info([LogMessage]::new("[Scheduler:SetSchedule] Scheduled message [$($ScheduledMessage.Id)] modified", $existingMessage))
        if ($existingMessage.Enabled) {
            $existingMessage.ResetTimer()
        }

        $this.SaveState()
        return $existingMessage
    }

    [ScheduledMessage]EnableSchedule([string]$Id) {
        if ($msg = $this.GetSchedule($Id)) {
            $this._Logger.Info([LogMessage]::new("[Scheduler:EnableSchedule] Enabled scheduled command [$($_.Id)] enabled"))
            $msg.Enable()
            $this.SaveState()
            return $msg
        } else {
            return $null
        }
    }

    [ScheduledMessage]DisableSchedule([string]$Id) {
        if ($msg = $this.GetSchedule($Id)) {
            $this._Logger.Info([LogMessage]::new("[Scheduler:DisableSchedule] Disabled scheduled command [$($_.Id)] enabled"))
            $msg.Disable()
            $this.SaveState()
            return $msg
        } else {
            return $null
        }
    }
}
