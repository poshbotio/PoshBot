
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
            Channel = $this.Channel
            IncludeCommands = $this.IncludeCommands
            ExcludeCommands = $this.ExcludeCommands
        }
    }
}
