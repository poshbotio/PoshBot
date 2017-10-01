
class ApprovalCommandConfiguration {
    [string]$PluginCommandExpression
    [System.Collections.ArrayList]$ApprovalGroups
    [bool]$PeerApproval

    ApprovalCommandConfiguration() {
        $this.PluginCommandExpression = [string]::Empty
        $this.ApprovalGroups = New-Object -TypeName System.Collections.ArrayList
        $this.PeerApproval = $true
    }
}
