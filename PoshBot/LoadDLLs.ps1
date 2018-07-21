
if (($null -eq $IsWindows) -or $IsWindows) {
    $platform = 'windows'
    Add-Type -Path "$PSScriptRoot/lib/$platform/netstandard.dll"
} else {
    $platform = 'linux'
}

@(
    Resolve-Path -Path "$PSScriptRoot/lib/$platform/Microsoft.Azure.Amqp.dll"
    Resolve-Path -Path "$PSScriptRoot/lib/$platform/Microsoft.Azure.ServiceBus.dll"
) | ForEach-Object {
    [Void][System.Reflection.Assembly]::LoadFrom($_)
}
