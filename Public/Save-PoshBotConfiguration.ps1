
function Save-PoshBotConfiguration {
    [cmdletbinding(SupportsShouldProcess)]
    param(
        [parameter(Mandatory, ValueFromPipeline)]
        [BotConfiguration[]]$InputObject,

        [string]$Path = (Join-Path -Path (Join-Path -Path $env:USERPROFILE -ChildPath '.poshbot') -ChildPath 'Bot.psd1'),

        [switch]$PassThru
    )

    process {
        foreach ($item in $InputObject) {
            if ($PSCmdlet.ShouldProcess($Path, 'Save PoshBot configuration')) {
                $hash = @{}
                $InputObject | Get-Member -MemberType Property | ForEach-Object {
                    $hash.Add($_.Name, $item.($_.Name))
                }

                $meta = $hash | ConvertTo-Metadata -WarningAction SilentlyContinue
                if (-not (Test-Path -Path $Path)) {
                    New-Item -Path $Path -ItemType File -Force | Out-Null
                }
                $meta | Out-file -FilePath $Path -Force -Encoding utf8

                if ($PSBoundParameters.ContainsKey('PassThru')) {
                    Get-Item -Path $Path | Select-Object -First 1
                }
            }
        }
    }
}
