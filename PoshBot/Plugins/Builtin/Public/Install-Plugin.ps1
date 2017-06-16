
function Install-Plugin {
    <#
    .SYNOPSIS
        Install a new plugin.
    .PARAMETER Name
        The name of the PoshBot plugin (PowerShell module) to install.
        The plugin must already exist in $env:PSModulePath or be present
        in on of the configured plugin repositories (PowerShell repositories).
        If not already installed, PoshBot will install the module from the repository.
    .PARAMETER Version
        The specific version of the plugin to install.
    .EXAMPLE
        !install-plugin nameit

        Install the [NameIt] plugin.
    .EXAMPLE
        !install-plugin --name PoshBot.XKCD --version 1.0.0

        Install version [1.0.0] of the [PoshBot.XKCD] plugin.
    #>
    [PoshBot.BotCommand(
        Aliases = ('ip', 'installplugin'),
        Permissions = 'manage-plugins'
    )]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Mandatory, Position = 0)]
        [string]$Name,

        [parameter(Position = 1)]
        [ValidateScript({
            if ($_ -as [Version]) {
                $true
            } else {
                throw 'Version parameter must be a valid semantic version string (1.2.3)'
            }
        })]
        [string]$Version
    )

    if ($Name -ne 'Builtin') {

        # Attempt to find the module in $env:PSModulePath or in the configurated repository
        if ($PSBoundParameters.ContainsKey('Version')) {
            $mod = Get-Module -Name $Name -ListAvailable | Where-Object {$_.Version -eq $Version}
        } else {
            $mod = @(Get-Module -Name $Name -ListAvailable | Sort-Object -Property Version -Descending)[0]
        }
        if (-not $mod) {

            # Attemp to find the module in our PS repository
            $findParams = @{
                Name = $Name
                Repository = $bot.Configuration.PluginRepository
                ErrorAction = 'SilentlyContinue'
            }
            if ($PSBoundParameters.ContainsKey('Version')) {
                $findParams.RequiredVersion = $Version
            }

            if ($onlineMod = Find-Module @findParams) {
                $onlineMod | Install-Module -Scope CurrentUser -Force -AllowClobber

                if ($PSBoundParameters.ContainsKey('Version')) {
                    $mod = Get-Module -Name $Name -ListAvailable | Where-Object {$_.Version -eq $Version}
                } else {
                    $mod = @(Get-Module -Name $Name -ListAvailable | Sort-Object -Property Version -Descending)[0]
                }
            }
        }

        if ($mod) {
            try {
                $existingPlugin = $Bot.PluginManager.Plugins[$Name]
                $existingPluginVersions = $existingPlugin.Keys
                if ($existingPluginVersions -notcontains $mod.Version) {
                    $Bot.PluginManager.InstallPlugin($mod.Path, $true)
                    $resp = Get-Plugin -Bot $bot -Name $Name -Version $mod.Version
                    if (-not ($resp | Get-Member -Name 'Title' -MemberType NoteProperty)) {
                        $resp | Add-Member -Name 'Title' -MemberType NoteProperty -Value $null
                    }
                    $resp.Title = "Plugin [$Name] version [$($mod.Version)] successfully installed"
                } else {
                    $resp = New-PoshBotCardResponse -Type Warning -Text "Plugin [$Name] version [$($mod.Version)] is already installed" -Title 'Plugin already installed'
                }
            } catch {
                $resp = New-PoshBotCardResponse -Type Error -Text $_.Exception.Message -Title 'Rut row' -ThumbnailUrl $thumb.rutrow
            }
        } else {
            if ($PSBoundParameters.ContainsKey('Version')) {
                $text = "Plugin [$Name] version [$Version] not found in configured plugin directory [$($Bot.Configuration.PluginDirectory)], PSModulePath, or repository [$($Bot.Configuration.PluginRepository)]"
            } else {
                $text = "Plugin [$Name] not found in configured plugin directory [$($Bot.Configuration.PluginDirectory)], PSModulePath, or repository [$($Bot.Configuration.PluginRepository)]"
            }
            $resp = New-PoshBotCardResponse -Type Warning -Text $text -ThumbnailUrl 'http://p1cdn05.thewrap.com/images/2015/06/don-draper-shrug.jpg'
        }
    } else {
        $resp = New-PoshBotCardResponse -Type Warning -Text 'The builtin plugin is already... well... builtin :)' -Title 'Not gonna do it'
    }

    $resp
}
