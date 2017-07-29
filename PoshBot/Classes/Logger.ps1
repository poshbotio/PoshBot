
class Logger {

    # The log directory
    [string]$LogDir

    hidden [string]$LogFile

    # Our logging level
    # Any log messages less than or equal to this will be logged
    [LogLevel]$LogLevel

    # The max size for the log files before rolling
    [int]$MaxSizeMB = 10

    # Number of each log file type to keep
    [int]$FilesToKeep = 5

    # Create logs files under provided directory
    Logger([string]$LogDir, [LogLevel]$LogLevel) {
        $this.LogDir = $LogDir
        $this.LogLevel = $LogLevel
        $this.LogFile = Join-Path -Path $this.LogDir -ChildPath 'PoshBot.log'
        $this.CreateLogFile()
        $this.Log([LogMessage]::new("Log level set to [$($this.LogLevel)]"))
    }

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

    # Write line to file
    hidden [void]WriteLine([string]$Message) {
        $sw = [System.IO.StreamWriter]::new($this.LogFile, [System.Text.Encoding]::UTF8)
        $sw.WriteLine($Message)
        $sw.Close()
    }

    # Checks to see if file in question is larger than the max size specified for the logger.
    # If it is, it will roll the log and delete older logs to keep our number of logs per log type to
    # our max specifiex in the logger.
    # Specified $Always = $true will roll the log regardless
    hidden [void]RollLog([string]$LogFile, [bool]$Always) {
        if (Test-Path -Path $LogFile) {
            if ((($file = Get-Item -Path $logFile) -and ($file.Length/1mb) -gt $this.MaxSizeMB) -or $Always) {
                # Remove the last item if it would go over the limit
                if (Test-Path -Path "$logFile.$($this.FilesToKeep)") {
                    Remove-Item -Path "$logFile.$($this.FilesToKeep)"
                }
                foreach ($i in $($this.FilesToKeep)..1) {
                    if (Test-path -Path "$logFile.$($i-1)") {
                        Move-Item -Path "$logFile.$($i-1)" -Destination "$logFile.$i"
                    }
                }
                Move-Item -Path $logFile -Destination "$logFile.$i"
                $null = New-Item -Path $LogFile -Type File -Force | Out-Null
            }
        }
    }
}