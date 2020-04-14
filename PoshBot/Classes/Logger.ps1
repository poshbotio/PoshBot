
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

    # Runspace pool to host a PowerShell thread for the log writer
    [System.Management.Automation.Runspaces.RunspacePool]$RunspacePool = [RunspaceFactory]::CreateRunspacePool(1, 1)

    # Concurrent blocking collection so items can be added to queue and the log writer thread will sit and wait for items
    [Collections.Concurrent.BlockingCollection[hashtable]]$LogQueue = [Collections.Concurrent.BlockingCollection[hashtable]]@{}

    # PowerShell thread for log writer
    [System.Management.Automation.PowerShell]$Thread

    # Thread handle
    [object]$Handle

    # Wait for items to show up in the queue and write them to disk
    [ScriptBlock]$LogWriter = {
        param(
            [Collections.Concurrent.BlockingCollection[hashtable]]$Queue,

            [string]$LogFile
        )

        # Create a new log file if it doesn't exist
        function CreateLogFile {
            [cmdletbinding()]
            param(
                [parameter(mandatory)]
                [string]$LogFile
            )

            if (Test-Path -Path $LogFile) {
                RollLog -LogFile $LogFile -Always
            }
            New-Item -Path $LogFile -ItemType File -Force
        }

        # Roll the log if needed
        function RollLog {
            [cmdletbinding()]
            param(
                [parameter(mandatory)]
                [string]$LogFile,

                [switch]$Always,

                [parameter(mandatory)]
                [int]$MaxLogSize,

                [parameter(mandatory)]
                [int]$MaxFilesToKeep
            )

            $keep = $MaxFilesToKeep - 1

            if (Test-Path -Path $LogFile) {
                if ((($file = Get-Item -Path $LogFile) -and ($file.Length/1mb) -gt $MaxLogSize) -or $Always.IsPresent) {
                    # Remove the last item if it would go over the limit
                    if (Test-Path -Path "$LogFile.$keep") {
                        Remove-Item -Path "$LogFile.$keep"
                    }
                    foreach ($i in $keep..1) {
                        if (Test-path -Path "$LogFile.$($i-1)") {
                            Move-Item -Path "$LogFile.$($i-1)" -Destination "$LogFile.$i"
                        }
                    }
                    Move-Item -Path $LogFile -Destination "$LogFile.$i"
                    New-Item -Path $LogFile -Type File -Force > $null
                }
            } else {
                CreateLogFile -LogFile $LogFile
            }
        }

        foreach($logInstruction in $Queue.GetConsumingEnumerable()) {
            RollLog -LogFile $logInstruction.LogFile -MaxLogSize $logInstruction.MaxLogSizeMB -MaxFilesToKeep $logInstruction.MaxFilesToKeep

            $sw = [System.IO.StreamWriter]::new($logInstruction.LogFile, [System.Text.Encoding]::UTF8)
            $sw.WriteLine($logInstruction.Message)
            $sw.Close()
        }
    }

    # Create logs files under provided directory
    Logger([string]$LogDir, [LogLevel]$LogLevel, [int]$MaxLogSizeMB, [int]$MaxLogsToKeep) {
        $this.LogDir      = $LogDir
        $this.LogLevel    = $LogLevel
        $this.MaxSizeMB   = $MaxLogSizeMB
        $this.FilesToKeep = $MaxLogsToKeep
        $this.LogFile     = Join-Path -Path $this.LogDir -ChildPath 'PoshBot.log'

        # Setup the runspace for the log writer
        $this.RunspacePool.Open()
        $this.Thread = [PowerShell]::create()
        $this.Thread.RunspacePool = $this.RunspacePool
        $this.Thread.AddScript($this.LogWriter) > $null
        $this.Thread.AddParameter('Queue', $this.LogQueue) > $null
        $this.Thread.AddParameter('LogFile', $this.LogFile) > $null
        $this.Thread.AddParameter('MaxLogSize', $this.MaxSizeMB) > $Null
        $this.Thread.AddParameter('MaxFilesToKeep', $this.FilesToKeep) > $Null
        $this.handle = $this.Thread.BeginInvoke()

        $this.Log([LogMessage]::new("Log level set to [$($this.LogLevel)]"))
    }

    hidden Logger() { }

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
            $this.Log($Message, $this.LogFile, $this.MaxSizeMB, $this.FilesToKeep)
        }
    }

    [void]Log([LogMessage]$Message, [string]$LogFile, [int]$MaxLogSizeMB, [int]$MaxLogsToKeep) {
        $logInstruction = @{
            LogFile       = $LogFile
            Message       = $Message.ToJson()
            MaxLogSizeMB  = $MaxLogSizeMB
            MaxLogsToKeep = $MaxLogsToKeep
        }
        $this.LogQueue.Add($logInstruction)
    }

    [void]Dispose() {
        $this.LogQueue.CompleteAdding()
        $this.Thread.EndInvoke($this.Handle)
        $this.Thread.Dispose()
        $this.RunspacePool.Dispose()
    }
}
