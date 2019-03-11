
# Track bot instnace(s) running as PS job
$script:botTracker = @{}

$script:pathSeperator = [IO.Path]::PathSeparator

$script:moduleBase = $PSScriptRoot

if (($null -eq $IsWindows) -or $IsWindows) {
    $homeDir = $env:USERPROFILE
} else {
    $homeDir = $env:HOME
}
$script:defaultPoshBotDir = (Join-Path -Path $homeDir -ChildPath '.poshbot')

$PSDefaultParameterValues = @{
    'ConvertTo-Json:Verbose' = $false
}

# Enforce TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
