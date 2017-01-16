
function Get-PoshBotConfiguration {
    [cmdletbinding()]
    param(
        [ValidateScript({
            if (Test-Path -Path $_) {
                if ( (Get-Item -Path $_).Extension -eq 'psd1') {
                    $true
                } else {
                    Throw 'Path must be to a valid .psd1 file'
                }
            } else {
                Throw 'Path is not valid'
            }
        })]
        [string]$Path = (Join-Path -Path (Join-Path -Path $env:USERPROFILE -ChildPath '.poshbot') -ChildPath 'Bot.psd1')
    )

    $hash = Import-PowerShellDataFile -Path $Path

    $config = [BotConfiguration]::new()
    $hash.Keys | Foreach-Object {
        if ($config | Get-Member -MemberType Property -Name $_) {
            $config.($_) = $hash[$_]
        }
    }

    $config
}
