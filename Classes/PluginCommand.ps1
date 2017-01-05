
class PluginCommand {
    [Plugin]$Plugin
    [Command]$Command

    PluginCommand([Plugin]$Plugin, [Command]$Command) {
        $this.Plugin = $Plugin
        $this.Command = $Command
    }
}
