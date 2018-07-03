
function Save-PoshBotConfiguration {
    <#
    .SYNOPSIS
        Saves a PoshBot configuration object to the filesystem in the form of a PowerShell data (.psd1) file.
    .DESCRIPTION
        PoshBot configurations can be stored on the filesytem in PowerShell data (.psd1) files.
        This function will save a previously created configuration object to the filesystem.
    .PARAMETER InputObject
        The bot configuration object to save to the filesystem.
    .PARAMETER Path
        The path to a PowerShell data (.psd1) file to save the configuration to.
    .PARAMETER Force
        Overwrites an existing configuration file.
    .PARAMETER PassThru
        Returns the configuration file path.
    .EXAMPLE
        PS C:\> Save-PoshBotConfiguration -InputObject $botConfig

        Saves the PoshBot configuration. If now -Path is specified, the configuration will be saved to $env:USERPROFILE\.poshbot\PoshBot.psd1.
    .EXAMPLE
        PS C:\> $botConfig | Save-PoshBotConfig -Path c:\mybot\mybot.psd1

        Saves the PoshBot configuration to [c:\mybot\mybot.psd1].
    .EXAMPLE
        PS C:\> $configFile = $botConfig | Save-PoshBotConfig -Path c:\mybot\mybot.psd1 -Force -PassThru

        Saves the PoshBot configuration to [c:\mybot\mybot.psd1] and Overwrites existing file. The new file will be returned.
    .INPUTS
        BotConfiguration
    .OUTPUTS
        System.IO.FileInfo
    .LINK
        Get-PoshBotConfiguration
    .LINK
        Start-PoshBot
    #>
    [cmdletbinding(SupportsShouldProcess)]
    param(
        [parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('Configuration')]
        [BotConfiguration]$InputObject,

        [string]$Path = (Join-Path -Path $script:defaultPoshBotDir -ChildPath 'PoshBot.psd1'),

        [switch]$Force,

        [switch]$PassThru
    )

    process {
        if ($PSCmdlet.ShouldProcess($Path, 'Save PoshBot configuration')) {
            $hash = @{}
            foreach ($prop in ($InputObject | Get-Member -MemberType Property)) {
                switch ($prop.Name) {
                    # Serialize ChannelRules, ApprovalConfiguration, and MiddlewareConfiguration propertes differently as
                    # ConvertTo-Metadata won't know how to do it since they're custom PoshBot classes
                    'ChannelRules' {
                        $hash.Add($prop.Name, $InputObject.($prop.Name).ToHash())
                        break
                    }
                    'ApprovalConfiguration' {
                        $hash.Add($prop.Name, $InputObject.($prop.Name).ToHash())
                        break
                    }
                    'MiddlewareConfiguration' {
                        $hash.Add($prop.Name, $InputObject.($prop.Name).ToHash())
                        break
                    }
                    Default {
                        $hash.Add($prop.Name, $InputObject.($prop.Name))
                        break
                    }
                }
            }

            $meta = $hash | ConvertTo-Metadata -WarningAction SilentlyContinue
            if (-not (Test-Path -Path $Path) -or $Force) {
                New-Item -Path $Path -ItemType File -Force | Out-Null

                $meta | Out-file -FilePath $Path -Force -Encoding utf8
                Write-Verbose -Message "PoshBot configuration saved to [$Path]"

                if ($PassThru) {
                    Get-Item -Path $Path | Select-Object -First 1
                }
            } else {
                Write-Error -Message 'File already exists. Use the -Force switch to overwrite the file.'
            }
        }
    }
}

Export-ModuleMember -Function 'Save-PoshBotConfiguration'
