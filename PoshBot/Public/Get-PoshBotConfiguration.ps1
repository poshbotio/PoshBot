
function Get-PoshBotConfiguration {
    <#
    .SYNOPSIS
        Gets a PoshBot configuration from a file.
    .DESCRIPTION
        PoshBot configurations can be stored on the filesytem in PowerShell data (.psd1) files.
        This functions will load that file and return a [BotConfiguration] object.
    .PARAMETER Path
        One or more paths to a PoshBot configuration file.
    .PARAMETER LiteralPath
        Specifies the path(s) to the current location of the file(s). Unlike the Path parameter, the value of LiteralPath is used exactly as it is typed.
        No characters are interpreted as wildcards. If the path includes escape characters, enclose it in single quotation marks. Single quotation
        marks tell PowerShell not to interpret any characters as escape sequences.
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
        AddCommandReactions              : True

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
    [cmdletbinding(DefaultParameterSetName = 'Path')]
    param(
        [parameter(
            Mandatory,
            ParameterSetName  = 'Path',
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [string[]]$Path,

        [parameter(
            Mandatory,
            ParameterSetName = 'LiteralPath',
            Position = 0,
            ValueFromPipelineByPropertyName
        )]
        [ValidateNotNullOrEmpty()]
        [Alias('PSPath')]
        [string[]]$LiteralPath
    )

    process {
        # Resolve path(s)
        if ($PSCmdlet.ParameterSetName -eq 'Path') {
            $paths = Resolve-Path -Path $Path | Select-Object -ExpandProperty Path
        } elseif ($PSCmdlet.ParameterSetName -eq 'LiteralPath') {
            $paths = Resolve-Path -LiteralPath $LiteralPath | Select-Object -ExpandProperty Path
        }

        foreach ($item in $paths) {
            if (Test-Path $item) {
                if ( (Get-Item -Path $item).Extension -eq '.psd1') {
                    Write-Verbose -Message "Loading bot configuration from [$item]"
                    $hash = Get-Content -Path $item -Raw | ConvertFrom-Metadata
                    $config = [BotConfiguration]::new()
                    $hash.Keys | Foreach-Object {
                        if ($config | Get-Member -MemberType Property -Name $_) {
                            $config.($_) = $hash[$_]
                        }
                    }
                    $config
                } else {
                    Throw 'Path must be to a valid .psd1 file'
                }
            } else {
                Write-Error -Message "Path [$item] is not valid."
            }
        }
    }
}

Export-ModuleMember -Function 'Get-PoshBotConfiguration'
