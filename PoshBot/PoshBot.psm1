
# Track bot instnace(s) running as PS job
$script:botTracker = @{}

$script:pathSeperator = [IO.Path]::PathSeparator

if (($IsWindows -eq $null) -or $IsWindows) {
    $script:defaultPoshBotDir = (Join-Path -Path $env:USERPROFILE -ChildPath '.poshbot')
} else {
    $script:defaultPoshBotDir = (Join-Path -Path $env:HOME -ChildPath '.poshbot')
}
