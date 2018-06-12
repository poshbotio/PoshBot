
class ApprovalConfiguration {
    [int]$ExpireMinutes
    [System.Collections.ArrayList]$Commands

    ApprovalConfiguration() {
        $this.ExpireMinutes = 30
        $this.Commands = New-Object -TypeName System.Collections.ArrayList
    }

    [hashtable]ToHash() {
        $hash = @{
            ExpireMinutes = $this.ExpireMinutes
        }
        $cmds = New-Object -TypeName System.Collections.ArrayList
        $this.Commands | Foreach-Object {
            $cmds.Add($_.ToHash()) > $null
        }
        $hash.Commands = $cmds

        return $hash
    }

    static [ApprovalConfiguration] Serialize([PSObject]$DeserializedObject) {
        $ac = [ApprovalConfiguration]::new()
        $ac.ExpireMinutes = $DeserializedObject.ExpireMinutes
        $DeserializedObject.Commands | ForEach-Object {
            $ac.Commands.Add(
                [ApprovalCommandConfiguration]::Serialize($_)
            ) > $null
        }

        return $ac
    }
}
