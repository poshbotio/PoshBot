
class ParsedCommand {
    [string]$CommandString
    [string]$Plugin = $null
    [string]$Command = $null
    [string]$Version = $null
    [hashtable]$NamedParameters = @{}
    [System.Collections.ArrayList]$PositionalParameters = (New-Object System.Collections.ArrayList)
    [datetime]$Time = (Get-Date).ToUniversalTime()
    [string]$From = $null
    [string]$FromName = $null
    [hashtable]$CallingUserInfo = @{}
    [string]$To = $null
    [string]$ToName = $null
    [Message]$OriginalMessage

    [pscustomobject]Summarize() {
        $o = $this | Select-Object -Property * -ExcludeProperty NamedParameters
        if ($this.Plugin -eq 'Builtin') {
            $np = $this.NamedParameters.GetEnumerator() | Where-Object {$_.Name -ne 'Bot'}
            $o | Add-Member -MemberType NoteProperty -Name NamedParameters -Value $np
        } else {
            $o | Add-Member -MemberType NoteProperty -Name NamedParameters -Value $this.NamedParameters
        }
        return [pscustomobject]$o
    }
}
