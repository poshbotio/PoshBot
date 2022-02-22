
function Get-Plugin {
    <#
    .SYNOPSIS
        Get the details of a specific plugin or list all plugins.
    .PARAMETER Name
        The name of the plugin to get.
    .PARAMETER Version
        The version of the plugin to get.
    .EXAMPLE
        !get-plugin builtin

        Get the details of the [builtin] plugin.
    .EXAMPLE
        !get-plugin --name builtin --version 0.5.0

        Get the details of version [0.5.0] of the [builtin] plugin.
    #>
    [PoshBot.BotCommand(
        Aliases = ('gp', 'getplugin')
    )]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Position = 0)]
        [string]$Name,

        [parameter(Position = 1)]
        [string]$Version
    )

    if ($PSBoundParameters.ContainsKey('Name')) {

        $p = $Bot.PluginManager.Plugins[$Name]
        if ($p) {

            $versions = New-Object -TypeName System.Collections.ArrayList

            if ($PSBoundParameters.ContainsKey('Version')) {
                if ($pv = $p[$Version]) {
                    $versions.Add($pv) > $null
                }
            } else {
                foreach ($pvk in $p.Keys | Sort-Object -Descending) {
                    $pv = $p[$pvk]
                    $versions.Add($pv) > $null
                }
            }

            if ($versions.Count -gt 0) {
                if ($PSBoundParameters.ContainsKey('Version')) {
                    $versions = $versions | Where-Object Version -eq $Version
                }
                foreach ($pv in $versions) {
                    $fields = [ordered]@{
                        Name = $pv.Name
                        Version = $pv.Version.ToString()
                        Enabled = $pv.Enabled.ToString()
                        CommandCount = $pv.Commands.Count
                        Permissions = $pv.Permissions.Keys | Format-List | Out-String
                        Commands = $pv.Commands.Keys | Sort-Object | Format-List | Out-String
                    }

                    $msg = [string]::Empty
                    $properties = @(
                        @{
                            Expression = {$_.Name}
                            Label = 'Name'
                        }
                        @{
                            Expression = {$_.Value.Description}
                            Label = 'Description'
                        }
                        @{
                            Expression = {$_.Value.Usage}
                            Label = 'Usage'
                        }
                    )
                    $msg += "`nCommands: `n$($pv.Commands.GetEnumerator() | Select-Object -Property $properties | Format-List | Out-String)"
                    New-PoshBotCardResponse -Type Normal -Fields $fields
                }
            } else {
                if ($PSBoundParameters.ContainsKey('Version')) {
                    New-PoshBotCardResponse -Type Warning -Text "Plugin [$Name] version [$Version] not found."
                } else {
                    New-PoshBotCardResponse -Type Warning -Text "Plugin [$Name] not found."
                }
            }
        } else {
            New-PoshBotCardResponse -Type Warning -Text "Plugin [$Name] not found."
        }
    } else {
        $plugins = foreach ($key in ($Bot.PluginManager.Plugins.Keys | Sort-Object)) {
            $p = $Bot.PluginManager.Plugins[$key]
            foreach ($versionKey in $p.Keys | Sort-Object -Descending) {
                $pluginVersion = $p[$versionKey]
                [pscustomobject][ordered]@{
                    Name = $key
                    Version = $pluginVersion.Version.ToString()
                    Enabled = $pluginVersion.Enabled
                }
            }
        }
        New-PoshBotCardResponse -Type Normal -Text ($plugins | Format-Table -AutoSize | Out-String -Width 80)
    }
}
