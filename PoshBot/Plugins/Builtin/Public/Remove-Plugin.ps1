
function Remove-Plugin {
    <#
    .SYNOPSIS
        Removes a currently loaded plugin.
    .PARAMETER Name
        The name of the plugin to remove.
    .PARAMETER Version
        The specific version of the plugin to remove.
    .EXAMPLE
        !remove-plugin nameit

        Remove the [NameIt] plugin.
    .EXAMPLE
        !remove-plugin --name PoshBot.XKCD --version 1.0.0

        Remove version [1.0.0] of the [PoshBot.XKCD] module.
    #>
    [PoshBot.BotCommand(
        Aliases = ('rp', 'removeplugin'),
        Permissions = 'manage-plugins'
    )]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Mandatory, Position = 0)]
        [string]$Name,

        [parameter(Position = 1)]
        [string]$Version
    )

    if ($Name -ne 'Builtin') {
        if ($p = $Bot.PluginManager.Plugins[$Name]) {
            $pv = $null
            if ($p.Keys.Count -gt 1) {
                if (-not $PSBoundParameters.ContainsKey('Version')) {
                    $versions = $p.Keys -join ', ' | Out-String
                    New-PoshBotCardResponse -Type Warning -Text "Plugin [$Name] has multiple versions installed. Specify version from list`n$versions" -ThumbnailUrl $thumb.warning
                    return
                } else {
                    $pv = $p[$Version]
                }
            } else {
                $pvKey = $p.Keys[0]
                $pv = $p[$pvKey]
            }

            if ($pv) {
                try {
                    $Bot.PluginManager.RemovePlugin($pv.Name, $pv.Version)
                    New-PoshBotCardResponse -Type Normal -Text "Plugin [$Name] version [$($pv.Version)] and all related commands have been removed." -Title 'Plugin Removed' -ThumbnailUrl $thumb.success
                } catch {
                    New-PoshBotCardResponse -Type Error -Text $_.Exception.Message -Title 'Rut row' -ThumbnailUrl $thumb.rutrow
                }
            } else {
                New-PoshBotCardResponse -Type Warning -Text "Plugin [$Name] version [$Version] not found." -ThumbnailUrl $thumb.warning
            }
        } else {
            New-PoshBotCardResponse -Type Warning -Text "Plugin [$Name] not found." -ThumbnailUrl $thumb.warning
        }
    } else {
        New-PoshBotCardResponse -Type Warning -Text "Sorry, builtin plugins can't be removed. It's for your own good :)" -Title 'Ya no'
    }
}
