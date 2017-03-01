
enum LogSeverity {
    Normal
    Warning
    Error
}

class LogMessage {
    [datetime]$DateTime = (Get-Date)
    [string]$Severity = [LogSeverity]::Normal
    [string]$LogLevel = [LogLevel]::Info
    [string]$Message
    [object]$Data

    LogMessage() {
    }

    LogMessage([string]$Message) {
        $this.Message = $Message
    }

    LogMessage([string]$Message, [object]$Data) {
        $this.Message = $Message
        $this.Data = $Data
    }

    LogMessage([LogSeverity]$Severity, [string]$Message, [object]$Data) {
        $this.Severity = $Severity
        $this.Message = $Message
        $this.Data = $Data
    }

    # Borrowed from https://github.com/PowerShell/PowerShell/issues/2736
    hidden [string]Compact([string]$Json) {
        $indent = 0
        $compacted = ($Json -Split '\n' | ForEach-Object {
            if ($_ -match '[\}\]]') {
                # This line contains  ] or }, decrement the indentation level
                $indent--
            }
            $line = (' ' * $indent * 2) + $_.TrimStart().Replace(':  ', ': ')
            if ($_ -match '[\{\[]') {
                # This line contains [ or {, increment the indentation level
                $indent++
            }
            $line
        }) -Join "`n"
        return $compacted
    }

    [string]ToJson() {
        $json = @{
            DataTime = $this.DateTime
            Severity = $this.Severity
            LogLevel = $this.LogLevel
            Message = $this.Message
            Data = $this.Data
        } | ConvertTo-Json -Depth 100 -Compress
        return $json
        #return $this.Compact($json)
    }

    [string]ToString() {
        return $this.ToJson()
    }
}

class Logger {

    # The log directory
    [string]$LogDir

    hidden [string]$LogFile

    # Out logging level
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
    }

    # Create new log file or roll old log
    hidden [void]CreateLogFile() {
        if (Test-Path -Path $this.LogFile) {
            $this.RollLog($this.LogFile, $true)
        }
        Write-Debug -Message "[Logger:Logger] Creating log file [$($this.LogFile)]"
        New-Item -Path $this.LogFile -ItemType File -Force
    }

    [void]Info([LogMessage]$Message) {
        $Message.LogLevel = [LogLevel]::Info
        $this.Log($Message)
    }

    [void]Verbose([LogMessage]$Message) {
        $Message.LogLevel = [LogLevel]::Verbose
        $this.Log($Message)
    }

    [void]Debug([LogMessage]$Message) {
        $Message.LogLevel = [LogLevel]::Debug
        $this.Log($Message)
    }

    # Write out message in JSON form to log file
    [void]Log([LogMessage]$Message) {

        if ($global:VerbosePreference -eq 'Continue') {
            Write-Verbose -Message $Message.ToJson()
        } elseIf ($global:DebugPreference -eq 'Continue') {
            Write-Debug -Message $Message.ToJson()
        }

        if ($Message.LogLevel.value__ -le $This.LogLevel.value__) {
            $this.RollLog($this.LogFile, $false)
            $json = $Message.ToJson()
            $json | Out-File -FilePath $this.LogFile -Append -Encoding utf8
        }
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
