
function Add-PoshBotPluginCommand {
    [cmdletbinding()]
    param(
        [parameter(Mandatory, ValueFromPipeline)]
        [Alias('Plugin')]
        [Plugin]$InputObject,

        [parameter(Mandatory)]
        [Command]$Command
    )

    Write-Verbose -Message "Adding command [$($Command.Name)] to plugin"
    $InputObject.AddCommand($Command)
}
