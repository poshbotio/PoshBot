
class ChannelRule {
    [string]$Channel
    [string[]]$IncludeCommands
    [string[]]$ExcludeCommands

    ChannelRule() {
        $this.Channel = '*'
        $this.IncludeCommands = @('*')
        $this.ExcludeCommands = @()
    }

    ChannelRule([string]$Channel, [string[]]$IncludeCommands, [string]$ExcludeCommands) {
        $this.Channel = $Channel
        $this.IncludeCommands = $IncludeCommands
        $this.ExcludeCommands = $ExcludeCommands
    }

    [hashtable]ToHash() {
        return @{
            Channel         = $this.Channel
            IncludeCommands = $this.IncludeCommands
            ExcludeCommands = $this.ExcludeCommands
        }
    }

    static [ChannelRule] Serialize([PSObject]$DeserializedObject) {
        $cr = [ChannelRule]::new()
        $cr.Channel = $DeserializedObject.Channel
        $cr.IncludeCommands = $DeserializedObject.IncludeCommands
        $cr.ExcludeCommands = $DeserializedObject.ExcludeCommands

        return $cr
    }
}
