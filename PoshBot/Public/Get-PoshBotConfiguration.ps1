
function Get-PoshBotConfiguration {
    <#
    .SYNOPSIS
        Gets a PoshBot configuration from a file.
    .DESCRIPTION
        PoshBot configurations can be stored on the filesytem in PowerShell data (.psd1) files.
        This functions will load that file and return a [BotConfiguration] object.
    .PARAMETER Path
        One or more paths to a PoshBot configuration file.
    .EXAMPLE
        PS C:\> Get-PoshBotConfiguration -Path C:\Users\joeuser\.poshbot\Cherry2000.psd1

        Name                             : Cherry2000
        ConfigurationDirectory           : C:\Users\joeuser\.poshbot
        LogDirectory                     : C:\Users\joeuser\.poshbot\Logs
        PluginDirectory                  : C:\Users\joeuser\.poshbot
        PluginRepository                 : {PSGallery}
        ModuleManifestsToLoad            : {}
        LogLevel                         : Debug
        BackendConfiguration             : {Token, Name}
        PluginConfiguration              : {}
        BotAdmins                        : {joeuser}
        CommandPrefix                    : !
        AlternateCommandPrefixes         : {bender, hal}
        AlternateCommandPrefixSeperators : {:, ,, ;}
        SendCommandResponseToPrivate     : {}
        MuteUnknownCommand               : False

        Gets the bot configuration located at [C:\Users\joeuser\.poshbot\Cherry2000.psd1].
    .EXAMPLE
        PS C:\> $botConfig = 'C:\Users\joeuser\.poshbot\Cherry2000.psd1' | Get-PoshBotConfiguration

        Gets the bot configuration located at [C:\Users\brand\.poshbot\Cherry2000.psd1].
    .INPUTS
        String
    .OUTPUTS
        BotConfiguration
    .LINK
        New-PoshBotConfiguration
    .LINK
        Start-PoshBot
    #>
    [cmdletbinding()]
    param(
        [parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
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
        [string[]]$Path = (Join-Path -Path (Join-Path -Path $env:USERPROFILE -ChildPath '.poshbot') -ChildPath 'PoshBot.psd1')
    )

    process {
        foreach ($item in $Path) {
            if (Test-Path $item) {
                Write-Verbose -Message "Loading bot configuration from [$item]"
                $hash = Import-PowerShellDataFile -Path $item
                $config = [BotConfiguration]::new()
                $hash.Keys | Foreach-Object {
                    if ($config | Get-Member -MemberType Property -Name $_) {
                        $config.($_) = $hash[$_]
                    }
                }

                $config
            } else {
                Write-Error -Message "Path [$item] is not valid."
            }
        }
    }
}

Export-ModuleMember -Function 'Get-PoshBotConfiguration'
