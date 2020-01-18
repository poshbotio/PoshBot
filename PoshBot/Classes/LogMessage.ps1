
class LogMessage {
    [datetime]$DateTime = [datetime]::UtcNow
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
        $this.Data    = $Data
    }

    LogMessage([LogSeverity]$Severity, [string]$Message) {
        $this.Severity = $Severity
        $this.Message  = $Message
    }

    LogMessage([LogSeverity]$Severity, [string]$Message, [object]$Data) {
        $this.Severity = $Severity
        $this.Message  = $Message
        $this.Data     = $Data
    }

    [string]ToJson() {
        $json = [ordered]@{
            DataTime = $this.DateTime.ToString('u')
            Class    = $this.Class
            Method   = $this.Method
            Severity = $this.Severity.ToString()
            LogLevel = $this.LogLevel.ToString()
            Message  = $this.Message
            Data = foreach ($item in $this.Data) {
                # Summarize exceptions so they can be serialized to json correctly

                # Don't try to serialize jobs
                if ($item.GetType().BaseType.ToString() -eq 'RunspaceJob') {
                    continue
                }

                # Summarize Error records so the json is easier to read and doesn't
                # contain a ton of unnecessary infomation
                if ($item -is [System.Management.Automation.ErrorRecord]) {
                    [ExceptionFormatter]::Summarize($item)
                } else {
                    $item
                }
            }
        } | ConvertTo-Json -Depth 10 -Compress

        return $json
    }

    [string]ToString() {
        return $this.ToJson()
    }
}
