class RunspaceJob {
    [System.Management.Automation.PowerShell]$PowerShell
    [System.IAsyncResult]$Handle

    RunspaceJob([string]$Name, [scriptblock]$Code, [hashtable]$Options) {
        $this.PowerShell = [PowerShell]::Create()

        # For some reason have to explicitly create a new runspace
        # Otherwise, after PowerShell.Dispose() gets called weird errors start happening e.g:
        #   Unable to find type [System.Net.Http.HttpClient]
        #   Object reference not set to an instance of an object.
        # Dispose() affects the current session???
        # Even calling Create() with [System.Management.Automation.RunspaceMode]::NewRunspace didn't seem to work
        $this.PowerShell.Runspace = [runspacefactory]::CreateRunspace()
        $this.PowerShell.Runspace.Name = $Name
        $this.PowerShell.Runspace.Open()

        $this | Add-Member -Name Id -Force -MemberType ScriptProperty -Value {
            return $this.PowerShell.Runspace.Id
        }

        $this.Handle = $this.PowerShell.AddScript($Code).AddParameter('Options', $Options).BeginInvoke()
    }

    [void]EndJob( [ref]$CommandResult ) {
        $CommandResult.Value.Errors              = $this.PowerShell.Streams.Error.ReadAll()
        $CommandResult.Value.Streams.Error       = $CommandResult.Value.Errors
        $CommandResult.Value.Streams.Information = $this.PowerShell.Streams.Information.ReadAll()
        $CommandResult.Value.Streams.Verbose     = $this.PowerShell.Streams.Verbose.ReadAll()
        $CommandResult.Value.Streams.Warning     = $this.PowerShell.Streams.Warning.ReadAll()

        try {
            $CommandResult.Value.Output  = $this.PowerShell.EndInvoke($this.Handle)
        } catch {
            # Unwrap the exception otherwise it will blame EndInvoke for the exception
            #   e.g. Exception calling "EndInvoke" with "1" argument(s): "Attempted to divide by zero."
            $CommandResult.Value.Errors = $_.Exception.InnerException.ErrorRecord
        } finally {
            $this.PowerShell.Dispose()
        }

        # # Job is deemed successful if no items in error stream
        $CommandResult.Value.Success = $CommandResult.Value.Errors -eq 0
    }
}
