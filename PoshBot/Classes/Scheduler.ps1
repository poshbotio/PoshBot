
class Scheduler {

    [hashtable]$Schedules = @{}

    [void]ScheduledMessage([ScheduledMessage]$ScheduledMessage) {
        if (-not $this.Schedules.ContainsKey($ScheduledMessage.Id)) {
            $this.Schedules.Add($ScheduledMessage.Id, $ScheduledMessage)
        } else {
            throw "Id [$($ScheduledMessage.Id)] is already scheduled"
        }
    }

    [void]RemoveScheduledMessage([string]$Id) {
        if ($this.Schedules.ContainsKey($id)) {
            $this.Schedules.Remove($id)
        } else {
            throw "Unknown schedule Id [$Id]"
        }
    }

    [ScheduledMessage[]]ListSchedules() {
        $result = New-Object -TypeName System.Collections.ArrayList
        $this.Schedules.GetEnumerator() |
            Select-Object -ExpandProperty Value |
            Sort-Object -Property TimeValue -Descending |
            Foreach-Object {
                switch ($_.TimeInterval) {
                    'Days' {
                        $interval = "$($_.TimeValue / 86400000)d"
                        break
                    }
                    'Hours' {
                        $interval = "$($_.TimeValue / 3600000)h"
                        break
                    }
                    'Minutes' {
                        $interval = "$($_.TimeValue / 60000)m"
                        break
                    }
                    'Seconds' {
                        $interval = "$($_.TimeValue / 1000)s"
                        break
                    }
                    Default {
                        $interval = 'unknown'
                        break
                    }
                }

                $s = [pscustomobject]@{
                    Id = $_.Id
                    Command = $_.Message.Text
                    Interval = $interval
                    Enabled = $_.Enabled
                }
                $result.Add($s) > $null
            }

        return $result
    }

    [Message[]]GetMessages() {
        $messages = $this.Schedules.GetEnumerator() | Foreach-Object {
            if ($_.Value.HasElapsed()) {
                $_.Value.ResetTimer()
                $_.Value.Message
            }
        }
        return $messages
    }

    [ScheduledMessage]EnableSchedule([string]$Id) {
        if ($msg = $this.Schedules[$Id]) {
            $msg.Enable()
            return $msg
        } else {
            throw "Unknown schedule Id [$Id]"
        }
    }

    [ScheduledMessage]DisableSchedule([string]$Id) {
        if ($msg = $this.Schedules[$Id]) {
            $msg.Disable()
            return $msg
        } else {
            throw "Unknown schedule Id [$Id]"
        }
    }
}
