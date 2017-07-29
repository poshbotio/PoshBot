
class LogMessage {
    [datetime]$DateTime = (Get-Date).ToUniversalTime()
    [string]$Class
    [string]$Method
    [LogSeverity]$Severity = [LogSeverity]::Normal
    [LogLevel]$LogLevel = [LogLevel]::Info
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

    LogMessage([LogSeverity]$Severity, [string]$Message) {
        $this.Severity = $Severity
        $this.Message = $Message
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
        $json = [ordered]@{
            DataTime = $this.DateTime.ToString('u')
            Class = $this.Class
            Method = $this.Method
            Severity = $this.Severity.ToString()
            LogLevel = $this.LogLevel.ToString()
            Message = $this.Message
            Data = foreach ($item in $this.Data) {
                # Summarize exceptions so they can be serialized to json correctly
                if ($item -is [System.Management.Automation.ErrorRecord]) {
                    $i = [ExceptionFormatter]::Summarize($item)
                } else {
                    $i = $item
                }
                $i | ConvertTo-Json -Depth 100 -Compress
            }
        } | ConvertTo-Json -Depth 100 -Compress
        return $json
    }

    [string]ToString() {
        return $this.ToJson()
    }
}
