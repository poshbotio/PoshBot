using module 'PoshBot'


class MockLogger : Logger {
    MockLogger() {
    }

    hidden [void]CreateLogFile() {
        Write-Debug -Message "[Logger:Logger] Creating log file [$($this.LogFile)]"
    }

    [void]Log([LogMessage]$Message) {
        Write-Debug -Message $Message.ToJson()
    }

    [void]Log([LogMessage]$Message, [string]$LogFile, [int]$MaxLogSizeMB, [int]$MaxLogsToKeep) {
        Write-Debug -Message $Message.ToJson()
    }

    hidden [void]WriteLine([string]$Message) {
        Write-Debug -Message $Message
    }

    hidden [void]RollLog([string]$LogFile, [bool]$Always) {
    }

    hidden [void]RollLog([string]$LogFile, [bool]$Always, $MaxLogSize, $MaxFilesToKeep) {
    }
}

class MockStorageProvider : StorageProvider {
    [string]$ConfigPath

    [hashtable]$Config

    MockStorageProvider([Logger]$Logger) : base($Logger) {
        $this.Config = @{}
    }

    [hashtable]GetConfig([string]$ConfigName) {
        if ($this.Config[$ConfigName]) {
            return $this.Config[$ConfigName]
        }
        else {
            return $null
        }
    }

    [void]SaveConfig([string]$ConfigName, [hashtable]$Config) {
        $this.Config[$ConfigName] = $Config
    }
}

InModuleScope PoshBot {

    Describe Scheduler {
        $Logger = [MockLogger]::New()
        $Storage = [MockStorageProvider]::New($Logger)

        $message = @{
            Id = ''
            Text = '!help'
            To = ''
            From = ''
            Type = 'Message'
            Subtype = 'None'
          }

        $Schedule = @{
            sched_test = @{
                StartAfter = (Get-Date).ToUniversalTime().AddDays(-5)
                Once = $False
                TimeValue = 1
                IntervalMS = 86400000
                Id = New-Guid
                TimeInterval = 'Days'
                Enabled = $True
                Message = $message
            }
        }

        $Storage.SaveConfig('schedules', $Schedule)

        Context 'Methods: LoadState()' {
            It 'Should not load schedules as triggered' {
                $scheduler = [Scheduler]::New($Storage, $Logger)

                $scheduler.GetTriggeredMessages().Count | Should Be 0
            }

            It 'Should not advance schedules whose triggers are in the future' {
                $futureSchedule = $Schedule['sched_test'].Clone()
                $futureSchedule['message'] = $message
                $futureSchedule['StartAfter'] = (Get-Date).ToUniversalTime().AddDays(5)

                $originalStartAfter = $futureSchedule['StartAfter']

                $Storage.SaveConfig('schedules', @{ sched_test = $futureSchedule })

                $scheduler = [Scheduler]::New($Storage, $Logger)

                ($scheduler.Schedules."$($futureSchedule.Id)").StartAfter | Should Be $originalStartAfter
            }
        }

    }
}
