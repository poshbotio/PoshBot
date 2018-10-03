[cmdletbinding()]
param(
    [parameter(Mandatory)]
    [ValidateScript({
        if (Test-Path -Path $_) {
            if ( (Get-Item -Path $_).Extension -eq '.psd1') {
                $true
            } else {
                Throw 'Path must be to a valid .psd1 file'
            }
        } else {
            Throw 'Path is not valid'
        }
    })]
    [string]$Path
)
Import-Module "$PSScriptRoot\..\PoshBot.psd1" -Force -ErrorAction Stop
Start-PoshBot -Path $Path
