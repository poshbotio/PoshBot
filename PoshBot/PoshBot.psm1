
# Track bot instnace(s) running as PS job
$script:botTracker = @{}

$script:pathSeperator = [IO.Path]::PathSeparator

$script:moduleBase = $PSScriptRoot

if (($null -eq $IsWindows) -or $IsWindows) {
    $script:defaultPoshBotDir = (Join-Path -Path $env:USERPROFILE -ChildPath '.poshbot')
    Add-Type -Path "$script:moduleBase/lib/windows/netstandard.dll"
} else {
    $script:defaultPoshBotDir = (Join-Path -Path $env:HOME -ChildPath '.poshbot')
}
