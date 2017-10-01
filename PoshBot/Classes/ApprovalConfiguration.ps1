
class ApprovalConfiguration {
    [int]$ExpireMinutes
    [System.Collections.ArrayList]$Commands

    ApprovalConfiguration() {
        $this.ExpireMinutes = 30
        $this.Commands = New-Object -TypeName System.Collections.ArrayList
    }
}
