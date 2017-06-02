
# A scheduled message that the scheduler class will return when the time interval
# has elapsed. The bot will treat this message as though it was returned from the
# chat network like a normal message
class ScheduledMessage {

    [string]$Id

    [TimeInterval]$TimeInterval

    [int]$TimeValue

    [Message]$Message

    [bool]$Enabled = $true

    [double]$IntervalMS

    [int]$TimesExecuted = 0

    [System.Diagnostics.Stopwatch]$Stopwatch

    ScheduledMessage([TimeInterval]$Interval, [int]$TimeValue, [Message]$Message, [bool]$Enabled) {
        $this.Id = (New-Guid).ToString() -Replace '-', ''
        $this.TimeInterval = $Interval
        $this.TimeValue = $TimeValue
        $this.Message = $Message
        $this.Enabled = $Enabled
        $this.Timer = New-Object -TypeName [System.Diagnostics.Stopwatch]

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

    ScheduledMessage([TimeInterval]$Interval, [int]$TimeValue, [Message]$Message) {
        $this.ScheduledMessage($Interval, $TimeValue, $Message, $true)
    }

    [bool]HasElapsed() {
        if ($this.Stopwatch.ElapsedMilliseconds -gt $this.IntervalMS) {
            $this.TimesExecuted += 1
            return $true
        } else {
            return $false
        }
    }

    [void]Enable() {
        $this.Enabled = $true
        $this.StartTimer()
    }

    [void]Disable() {
        $this.Enabled = $false
        $this.StopTimer()
    }

    [void]StartTimer() {
        $this.Stopwatch.Start()
    }

    [void]StopTimer() {
        $this.Stopwatch.Stop()
    }

    [void]ResetTimer() {
        $this.Stopwatch.Reset()
    }
}
