
# A scheduled message that the scheduler class will return when the time interval
# has elapsed. The bot will treat this message as though it was returned from the
# chat network like a normal message
class ScheduledMessage {

    [string]$Id = (New-Guid).ToString() -Replace '-', ''

    [TimeInterval]$TimeInterval

    [int]$TimeValue

    [Message]$Message

    [bool]$Enabled = $true

    [bool]$Once = $false

    [double]$IntervalMS

    [int]$TimesExecuted = 0

    [DateTime]$StartAfter = (Get-Date).ToUniversalTime()

    ScheduledMessage([TimeInterval]$Interval, [int]$TimeValue, [Message]$Message, [bool]$Enabled, [DateTime]$StartAfter) {
        $this.Init($Interval, $TimeValue, $Message, $Enabled, $StartAfter)
    }

    ScheduledMessage([TimeInterval]$Interval, [int]$TimeValue, [Message]$Message, [bool]$Enabled) {
        $this.Init($Interval, $TimeValue, $Message, $Enabled, (Get-Date).ToUniversalTime())
    }

    ScheduledMessage([TimeInterval]$Interval, [int]$TimeValue, [Message]$Message, [DateTime]$StartAfter) {
        $this.Init($Interval, $TimeValue, $Message, $true, $StartAfter)
    }

    ScheduledMessage([TimeInterval]$Interval, [int]$TimeValue, [Message]$Message) {
        $this.Init($Interval, $TimeValue, $Message, $true, (Get-Date).ToUniversalTime())
    }

    ScheduledMessage([Message]$Message, [Datetime]$StartAt) {
        $this.Message = $Message
        $this.Enabled = $true
        $this.Once = $true
        $this.StartAfter = $StartAt.ToUniversalTime()
    }

    [void]Init([TimeInterval]$Interval, [int]$TimeValue, [Message]$Message, [bool]$Enabled, [DateTime]$StartAfter) {
        $this.TimeInterval = $Interval
        $this.TimeValue = $TimeValue
        $this.Message = $Message
        $this.Enabled = $Enabled
        $this.StartAfter = $StartAfter.ToUniversalTime()

        switch ($this.TimeInterval) {
            'Days' {
                $this.IntervalMS = ($TimeValue * 86400000)
                break
            }
            'Hours' {
                $this.IntervalMS = ($TimeValue * 3600000)
                break
            }
            'Minutes' {
                $this.IntervalMS = ($TimeValue * 60000)
                break
            }
            'Seconds' {
                $this.IntervalMS = ($TimeValue * 1000)
                break
            }
        }
    }

    [bool]HasElapsed() {
        $now = (Get-Date).ToUniversalTime()
        if ($now -gt $this.StartAfter) {
            $this.TimesExecuted += 1
            return $true
        } else {
            return $false
        }
    }

    [void]Enable() {
        $this.Enabled = $true
    }

    [void]Disable() {
        $this.Enabled = $false
    }

    [void]RecalculateStartAfter() {
        $currentDate = (Get-Date).ToUniversalTime()
        $difference = (New-TimeSpan $this.StartAfter $currentDate)
        $elapsedIntervals = [int][Math]::Ceiling($difference.TotalMilliseconds / $this.IntervalMS)
        #Always move forward at least one interval
        if ($elapsedIntervals -lt 1) {
            $elapsedIntervals = 1
        }
        $this.StartAfter = $this.StartAfter.AddMilliseconds($this.IntervalMS * $elapsedIntervals)
    }

    [hashtable]ToHash() {
        return @{
            Id = $this.Id
            TimeInterval = $this.TimeInterval.ToString()
            TimeValue = $this.TimeValue
            StartAfter = $This.StartAfter.ToUniversalTime()
            Once = $this.Once
            Message = @{
                Id = $this.Message.Id
                Type = $this.Message.Type.ToString()
                Subtype = $this.Message.Subtype.ToString()
                Text = $this.Message.Text
                To = $this.Message.To
                From = $this.Message.From
            }
            Enabled = $this.Enabled
            IntervalMS = $this.IntervalMS
        }
    }
}
