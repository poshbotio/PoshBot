
class BaseLogger {

    [Logger]$Logger

    BaseLogger() {}

    BaseLogger([string]$LogDirectory, [LogLevel]$LogLevel, [int]$MaxLogSizeMB, [int]$MaxLogsToKeep) {
        $this.Logger = [Logger]::new($LogDirectory, $LogLevel, $MaxLogSizeMB, $MaxLogsToKeep)
    }

    [void]LogInfo([string]$Message) {
        $logMessage = [LogMessage]::new($Message)
        $logMessage.LogLevel = [LogLevel]::Info
        $this.Log($logMessage)
    }

    [void]LogInfo([string]$Message, [object]$Data) {
        $logMessage = [LogMessage]::new($Message, $Data)
        $logMessage.LogLevel = [LogLevel]::Info
        $this.Log($logMessage)
    }

    [void]LogInfo([LogSeverity]$Severity, [string]$Message) {
        $logMessage = [LogMessage]::new($Severity, $Message)
        $logMessage.LogLevel = [LogLevel]::Info
        $this.Log($logMessage)
    }

    [void]LogInfo([LogSeverity]$Severity, [string]$Message, [object]$Data) {
        $logMessage = [LogMessage]::new($Severity, $Message, $Data)
        $logMessage.LogLevel = [LogLevel]::Info
        $this.Log($logMessage)
    }

    [void]LogVerbose([string]$Message) {
        $logMessage = [LogMessage]::new($Message)
        $logMessage.LogLevel = [LogLevel]::Verbose
        $this.Log($logMessage)
    }

    [void]LogVerbose([string]$Message, [object]$Data) {
        $logMessage = [LogMessage]::new($Message, $Data)
        $logMessage.LogLevel = [LogLevel]::Verbose
        $this.Log($logMessage)
    }

    [void]LogVerbose([LogSeverity]$Severity, [string]$Message) {
        $logMessage = [LogMessage]::new($Severity, $Message)
        $logMessage.LogLevel = [LogLevel]::Verbose
        $this.Log($logMessage)
    }

    [void]LogVerbose([LogSeverity]$Severity, [string]$Message, [object]$Data) {
        $logMessage = [LogMessage]::new($Severity, $Message, $Data)
        $logMessage.LogLevel = [LogLevel]::Verbose
        $this.Log($logMessage)
    }

    [void]LogDebug([string]$Message) {
        $logMessage = [LogMessage]::new($Message)
        $logMessage.LogLevel = [LogLevel]::Debug
        $this.Log($logMessage)
    }

    [void]LogDebug([string]$Message, [object]$Data) {
        $logMessage = [LogMessage]::new($Message, $Data)
        $logMessage.LogLevel = [LogLevel]::Debug
        $this.Log($logMessage)
    }

    [void]LogDebug([LogSeverity]$Severity, [string]$Message) {
        $logMessage = [LogMessage]::new($Severity, $Message)
        $logMessage.LogLevel = [LogLevel]::Debug
        $this.Log($logMessage)
    }

    [void]LogDebug([LogSeverity]$Severity, [string]$Message, [object]$Data) {
        $logMessage = [LogMessage]::new($Severity, $Message, $Data)
        $logMessage.LogLevel = [LogLevel]::Debug
        $this.Log($logMessage)
    }

    # Determine source class/method that called the log method
    # and add to log message before sending to logger
    hidden [void]Log([LogMessage]$Message) {
        $Message.Class = $this.GetType().Name
        $Message.Method = @(Get-PSCallStack)[2].FunctionName
        $this.Logger.Log($Message)
    }
}
