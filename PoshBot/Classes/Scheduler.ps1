
class Scheduler {

    [hashtable]$Schedules = @{}

    [void]ScheduleMessage([ScheduledMessage]$ScheduledMessage) {
        if (-not $this.Schedules.ContainsKey($ScheduledMessage.Id)) {
            Write-Verbose -Message "[Scheduler:ScheduleMessage] Scheduled message [$($_.Value.Id)]"
            $ScheduledMessage.StartTimer()
            $this.Schedules.Add($ScheduledMessage.Id, $ScheduledMessage)
        } else {
            Write-Error "Id [$($ScheduledMessage.Id)] is already scheduled"
        }
    }

    [void]RemoveScheduledMessage([string]$Id) {
        if ($this.GetSchedule($Id)) {
            Write-Verbose -Message "[Scheduler:RemoveScheduledMessage] Scheduled message [$($_.Value.Id)] removed"
            $this.Schedules.Remove($id)
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
                Write-Verbose -Message "[Scheduler:GetMessages] Timer reached on scheduled command [$($_.Value.Id)]"
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
            Write-Error -Message "Unknown schedule Id [$Id]"
            return $null
        }
    }

    [ScheduledMessage]SetSchedule([ScheduledMessage]$ScheduledMessage) {
        $existingMessage = $this.GetSchedule($ScheduledMessage.Id)
        $existingMessage.Init($ScheduledMessage.TimeInterval, $ScheduledMessage.TimeValue, $ScheduledMessage.Message, $ScheduledMessage.Enabled)
        if ($existingMessage.Enabled) {
            $existingMessage.ResetTimer()
        }
        return $existingMessage
    }

    [ScheduledMessage]EnableSchedule([string]$Id) {
        if ($msg = $this.GetSchedule($Id)) {
            Write-Verbose -Message "[Scheduler:EnableSchedule] Enabled scheduled command [$($_.Value.Id)] enabled"
            $msg.Enable()
            return $msg
        } else {
            return $null
        }
    }

    [ScheduledMessage]DisableSchedule([string]$Id) {
        if ($msg = $this.GetSchedule($Id)) {
            Write-Verbose -Message "[Scheduler:DisableSchedule] Disabled scheduled command [$($_.Value.Id)] enabled"
            $msg.Disable()
            return $msg
        } else {
            return $null
        }
    }
}
