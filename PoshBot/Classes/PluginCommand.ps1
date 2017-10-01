
class PluginCommand {
    [Plugin]$Plugin
    [Command]$Command

    PluginCommand([Plugin]$Plugin, [Command]$Command) {
        $this.Plugin = $Plugin
        $this.Command = $Command
    }

    [string]ToString() {
        return "$($this.Plugin.Name):$($this.Command.Name):$($this.Plugin.Version.ToString())"
    }
}
