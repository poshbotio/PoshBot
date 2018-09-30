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

        $Schedule = @{
            sched_test = @{
                StartAfter = (Get-Date).ToUniversalTime().AddDays(-5)
                Once = $False
                TimeValue = 1
                IntervalMS = 86400000
                Id = New-Guid
                TimeInterval = 'Days'
                Enabled = $True
                Message = @{
                  Id = ''
                  Text = '!help'
                  To = ''
                  From = ''
                  Type = 'Message'
                  Subtype = 'None'
                }
            }
        }

        $Storage.SaveConfig('schedules', $Schedule)

        Context 'Methods: LoadState()' {
            It 'Schedules should not be loaded as triggered' {
                $scheduler = [Scheduler]::New($Storage, $Logger)

                $scheduler.GetTriggeredMessages().Count | Should Be 0
            }
        }

    }
}
