
class Logger {

    # The log directory
    [string]$LogDir

    hidden [string]$LogFile

    # Our logging level
    # Any log messages less than or equal to this will be logged
    [LogLevel]$LogLevel

    # The max size for the log files before rolling
    [int]$MaxSizeMB

    # Number of each log file type to keep
    [int]$FilesToKeep

    # Create logs files under provided directory
    Logger([string]$LogDir, [LogLevel]$LogLevel, [int]$MaxLogSizeMB, [int]$MaxLogsToKeep) {
        $this.LogDir = $LogDir
        $this.LogLevel = $LogLevel
        $this.MaxSizeMB = $MaxLogSizeMB
        $this.FilesToKeep = $MaxLogsToKeep
        $this.LogFile = Join-Path -Path $this.LogDir -ChildPath 'PoshBot.log'
        $this.CreateLogFile()
        $this.Log([LogMessage]::new("Log level set to [$($this.LogLevel)]"))
    }

    hidden Logger() { }

    # Create new log file or roll old log
    hidden [void]CreateLogFile() {
        if (Test-Path -Path $this.LogFile) {
            $this.RollLog($this.LogFile, $true)
        }
        Write-Debug -Message "[Logger:Logger] Creating log file [$($this.LogFile)]"
        New-Item -Path $this.LogFile -ItemType File -Force
    }

    # Log the message and optionally write to console
    [void]Log([LogMessage]$Message) {
        switch ($Message.Severity.ToString()) {
            'Normal' {
                if ($global:VerbosePreference -eq 'Continue') {
                    Write-Verbose -Message $Message.ToJson()
                } elseIf ($global:DebugPreference -eq 'Continue') {
                    Write-Debug -Message $Message.ToJson()
                }
                break
            }
            'Warning' {
                if ($global:WarningPreference -eq 'Continue') {
                    Write-Warning -Message $Message.ToJson()
                }
                break
            }
            'Error' {
                if ($global:ErrorActionPreference -eq 'Continue') {
                    Write-Error -Message $Message.ToJson()
                }
                break
            }
        }

        if ($Message.LogLevel.value__ -le $this.LogLevel.value__) {
            $this.RollLog($this.LogFile, $false)
            $json = $Message.ToJson()
            $this.WriteLine($json)
        }
    }

    [void]Log([LogMessage]$Message, [string]$LogFile, [int]$MaxLogSizeMB, [int]$MaxLogsToKeep) {
        $this.RollLog($LogFile, $false, $MaxLogSizeMB, $MaxLogSizeMB)
        $json = $Message.ToJson()
        $sw = [System.IO.StreamWriter]::new($LogFile, [System.Text.Encoding]::UTF8)
        $sw.WriteLine($json)
        $sw.Close()
    }

    # Write line to file
    hidden [void]WriteLine([string]$Message) {
        $sw = [System.IO.StreamWriter]::new($this.LogFile, [System.Text.Encoding]::UTF8)
        $sw.WriteLine($Message)
        $sw.Close()
    }

    hidden [void]RollLog([string]$LogFile, [bool]$Always) {
        $this.RollLog($LogFile, $Always, $this.MaxSizeMB, $this.FilesToKeep)
    }

    # Checks to see if file in question is larger than the max size specified for the logger.
    # If it is, it will roll the log and delete older logs to keep our number of logs per log type to
    # our max specifiex in the logger.
    # Specified $Always = $true will roll the log regardless
    hidden [void]RollLog([string]$LogFile, [bool]$Always, $MaxLogSize, $MaxFilesToKeep) {

        $keep = $MaxFilesToKeep - 1

        if (Test-Path -Path $LogFile) {
            if ((($file = Get-Item -Path $logFile) -and ($file.Length/1mb) -gt $MaxLogSize) -or $Always) {
                # Remove the last item if it would go over the limit
                if (Test-Path -Path "$logFile.$keep") {
                    Remove-Item -Path "$logFile.$keep"
                }
                foreach ($i in $keep..1) {
                    if (Test-path -Path "$logFile.$($i-1)") {
                        Move-Item -Path "$logFile.$($i-1)" -Destination "$logFile.$i"
                    }
                }
                Move-Item -Path $logFile -Destination "$logFile.$i"
                New-Item -Path $LogFile -Type File -Force > $null
            }
        }
    }
}
