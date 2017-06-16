
function Enable-Plugin {
    <#
    .SYNOPSIS
        Enable a currently loaded plugin.
    .PARAMETER Name
        The name of the plugin to enable.
    .PARAMETER Version
        The specific version of the plugin to enable.
    .EXAMPLE
        !enable-plugin nameit

        Enable the [NameIt] plugin.
    .EXAMPLE
        !enable-plugin --name PoshBot.XKCD --version 1.0.0

        Enable version [1.0.0] of the [PoshBot.XKCD] module.
    #>
    [PoshBot.BotCommand(
        Aliases = 'enableplugin',
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
                    return New-PoshBotCardResponse -Type Warning -Text "Plugin [$Name] has multiple versions installed. Specify version from list`n$versions" -ThumbnailUrl $thumb.warning
                } else {
                    $pv = $p[$Version]
                }
            } else {
                $pvKey = $p.Keys[0]
                $pv = $p[$pvKey]
            }

            if ($pv) {
                try {
                    $Bot.PluginManager.ActivatePlugin($pv.Name, $pv.Version)
                    #$Bot.PluginManager.ActivatePlugin($pv)
                    #Write-Output "Plugin [$Plugin] activated. All commands in this plugin are now enabled."
                    return New-PoshBotCardResponse -Type Normal -Text "Plugin [$Name] activated. All commands in this plugin are now enabled." -ThumbnailUrl $thumb.success
                } catch {
                    #Write-Error $_
                    return New-PoshBotCardResponse -Type Error -Text $_.Exception.Message -Title 'Rut row' -ThumbnailUrl $thumb.rutrow
                }
            } else {
                return New-PoshBotCardResponse -Type Warning -Text "Plugin [$Name] version [$Version] not found." -ThumbnailUrl $thumb.warning
            }
        } else {
            #Write-Warning "Plugin [$Plugin] not found."
            return New-PoshBotCardResponse -Type Warning -Text "Plugin [$Name] not found." -ThumbnailUrl $thumb.warning
        }
    } else {
        #Write-Output "Builtin plugins can't be disabled so no need to enable them."
        return New-PoshBotCardResponse -Type Normal -Text "Builtin plugins can't be disabled so no need to enable them." -Title 'Ya no'
    }
}
