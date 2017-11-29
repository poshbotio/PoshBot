
class ChannelApprovedCommand {
    [string]$Channel
    [string[]]$IncludeCommands
    [string[]]$ExcludeCommands

    ChannelApprovedCommand() {
        $this.Channel = '*'
        $this.IncludeCommands = @('*')
        $this.ExcludeCommands = @()
    }

    ChannelApprovedCommand([string]$Channel, [string[]]$IncludeCommands, [string]$ExcludeCommands) {
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
