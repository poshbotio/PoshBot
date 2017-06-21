
function About {
    <#
    .SYNOPSIS
        Display details about PoshBot.
    .EXAMPLE
        !about
    #>
    [PoshBot.BotCommand(
        Permissions = 'view'
    )]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot
    )

    $path = "$PSScriptRoot/../../../PoshBot.psd1"
    $manifest = Import-PowerShellDataFile -Path $path
    $ver = $manifest.ModuleVersion

    $msg = @"
PoshBot v$ver
$($manifest.CopyRight)

https://github.com/poshbotio/PoshBot
"@

    New-PoshBotTextResponse -Text $msg -AsCode
}
