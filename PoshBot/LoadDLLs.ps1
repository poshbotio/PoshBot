
if (($null -eq $IsWindows) -or $IsWindows) {
    Add-Type -Path "$PSScriptRoot/lib/netstandard.dll"
}

@(
    Resolve-Path -Path "$PSScriptRoot/lib/Microsoft.Azure.Amqp.dll"
    Resolve-Path -Path "$PSScriptRoot/lib/Microsoft.Azure.ServiceBus.dll"
) | ForEach-Object {
    [Void][System.Reflection.Assembly]::LoadFrom($_)
}
