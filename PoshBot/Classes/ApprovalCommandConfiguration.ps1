
class ApprovalCommandConfiguration {
    [string]$Expression
    [System.Collections.ArrayList]$ApprovalGroups
    [bool]$PeerApproval

    ApprovalCommandConfiguration() {
        $this.Expression = [string]::Empty
        $this.ApprovalGroups = New-Object -TypeName System.Collections.ArrayList
        $this.PeerApproval = $true
    }

    [hashtable]ToHash() {
        return @{
            Expression   = $this.Expression
            Groups       = $this.ApprovalGroups
            PeerApproval = $this.PeerApproval
        }
    }

    static [ApprovalCommandConfiguration] Serialize([PSObject]$DeserializedObject) {
        $acc = [ApprovalCommandConfiguration]::new()
        $acc.Expression     = $DeserializedObject.Expression
        $acc.ApprovalGroups = $DeserializedObject.ApprovalGroups
        $acc.PeerApproval   = $DeserializedObject.PeerApproval

        return $acc
    }
}
