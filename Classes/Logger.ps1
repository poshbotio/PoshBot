
class LogMessage {
    [datetime]$DateTime
    [string]$Message
    [object]$Data

    LogMessage() {
        $this.DateTime = Get-Date
    }

    LogMessage([string]$Message) {
        $this.Message = $Message
        $this.DateTime = Get-Date
    }

    LogMessage([string]$Message, [object]$Data) {
        $this.Message = $Message
        $this.Data = $Data
        $this.DateTime = Get-Date
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
            Message = $this.Message
            Data = $this.Data
        } | ConvertTo-Json -Depth 100
        return $this.Compact($json)
    }

    [string]ToString() {
        return $this.ToJson()
    }
}

class Logger {

    # The log directory
    [string]$LogDir

    hidden [hashtable]$_file = @{}

    # The max size for the log files before rolling
    [int]$MaxSizeMB = 10

    # Number of each log file type to keep
    [int]$FilesToKeep = 5

    # Create default log files under user directory
    Logger() {
        $this.LogDir = Join-Path -Path $env:USERPROFILE -ChildPath '.poshbot'
        $this.PopulateFilenameHash()
        $this.RollLogs($true)
        $this.CreateLogFiles()
    }

    # Create logs files under provided directory
    Logger([string]$LogDir) {
        $this.LogDir = $LogDir
        $this.PopulateFilenameHash()
        $this.RollLogs($true)
        $this.CreateLogFiles()
    }

    hidden [void]PopulateFilenameHash() {
        $date = (Get-Date).ToString('yyyyMMdd')
        foreach ($type in [enum]::GetNames([LogType])) {
            $this._file.$type = Join-Path -Path $this.LogDir -ChildPath "$($type)_$($date).log"
        }
    }

    # Create our log files based on the current date
    hidden [void]CreateLogFiles() {
        foreach ($type in [enum]::GetNames([LogType])) {
            if (-not (Test-Path -Path $this._file["$type"])) {
                Write-Debug -Message "[Logger:Logger] Creating default log file [$($this._file.$type)]"
                New-Item -Path $this._file["$type"] -ItemType File -Force
            } else {
                New-Item -Path $this._file["$type"] -ItemType File -Force
            }
        }
    }

    # Write out message in JSON form to log file
    [void]Log([LogMessage]$Message, [LogType]$Type) {
        $this.PopulateFilenameHash()
        $json = $Message.ToJson()

        $file = $this._file["$Type"]
        $this.RollLog($file, $false)
        $json | Out-File -FilePath $file -Append -Encoding utf8
    }

    # Roll all the logs
    hidden [void]RollLogs([bool]$Always) {
        foreach ($key in $this._file.Keys) {
            $this.RollLog($this._file["$key"], $Always)
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
