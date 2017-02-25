
function Add-PoshBotPlugin {
    [cmdletbinding()]
    param(
        [parameter(Mandatory, ValueFromPipeline)]
        [Alias('Bot')]
        [Bot]$InputObject,

        [parameter(Mandatory)]
        [ValidateScript({Test-Path -Path $_})]
        [string]$ModuleManifest
    )
    Write-Verbose -Message "Creating bot plugin from module [$ModuleManifest]"
    $bot.PluginManager.InstallPlugin($ModuleManifest)
}
