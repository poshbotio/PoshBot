
class ChannelApprovedCommand {
    [string]$Channel
    [string[]]$Commands

    ChannelApprovedCommand() {
        $this.Channel = '*'
        $this.Commands = @('*')
    }

    ChannelApprovedCommand([string]$Channel, [string[]]$Commands) {
        $this.Channel = $Channel
        $this.Commands = $Commands
    }

    [hashtable]ToHash() {
        return @{
            Channel = $this.Channel
            Commands = $this.Commands
        }
    }
}
