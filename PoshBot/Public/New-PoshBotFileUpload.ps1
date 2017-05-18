
function New-PoshBotFileUpload {
    <#
    .SYNOPSIS
        Tells PoshBot to upload a file to the chat network.
    .DESCRIPTION
        Returns a custom object back to PoshBot telling it to upload the given file to the chat network. The custom object
        can also tell PoshBot to redirect the file upload to a DM channel with the calling user. This could be useful if
        the contents the bot command returns are sensitive and should not be visible to all users in the channel.
    .PARAMETER Path
        The path(s) to one or more files to upload. Wildcards are permitted.
    .PARAMETER LiteralPath
        Specifies the path(s) to the current location of the file(s). Unlike the Path parameter, the value of LiteralPath is used exactly as it is typed.
        No characters are interpreted as wildcards. If the path includes escape characters, enclose it in single quotation marks. Single quotation
        marks tell PowerShell not to interpret any characters as escape sequences.
    .PARAMETER Title
        The title for the uploaded file.
    .PARAMETER DM
        Tell PoshBot to redirect the file upload to a DM channel.
    .EXAMPLE
        function Do-Stuff {
            [cmdletbinding()]
            param()

            $myObj = [pscustomobject]@{
                value1 = 'foo'
                value2 = 'bar'
            }

            $csv = Join-Path -Path $env:TEMP -ChildPath "$((New-Guid).ToString()).csv"
            $myObj | Export-Csv -Path $csv -NoTypeInformation

            New-PoshBotFileUpload -Path $csv
        }

        Export a CSV file and tell PoshBot to upload the file back to the channel that initiated this command.

    .EXAMPLE
        function Get-SecretPlan {
            [cmdletbinding()]
            param()

            $myObj = [pscustomobject]@{
                Title = 'Secret moon base'
                Description = 'Plans for secret base on the dark side of the moon'
            }

            $csv = Join-Path -Path $env:TEMP -ChildPath "$((New-Guid).ToString()).csv"
            $myObj | Export-Csv -Path $csv -NoTypeInformation

            New-PoshBotFileUpload -Path $csv -Title 'YourEyesOnly.csv' -DM
        }

        Export a CSV file and tell PoshBot to upload the file back to a DM channel with the calling user.
    .INPUTS
        String
    .OUTPUTS
        PSCustomObject
    .LINK
        New-PoshBotCardResponse
    .LINK
        New-PoshBotTextResponse
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope='Function', Target='*')]
    [cmdletbinding()]
    param(
        [parameter(
            Mandatory = $true,
            ParameterSetName  = 'Path',
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [string[]]$Path,

        [parameter(
            Mandatory = $true,
            ParameterSetName = 'LiteralPath',
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [string[]]$LiteralPath,

        [string]$Title = [string]::Empty,

        [switch]$DM
    )

    process {
        # Resolve path(s)
        if ($PSCmdlet.ParameterSetName -eq "Path") {
            $paths = Resolve-Path -Path $Path | Select-Object -ExpandProperty Path
        } elseif ($PSCmdlet.ParameterSetName -eq "LiteralPath") {
            $paths = Resolve-Path -LiteralPath $LiteralPath | Select-Object -ExpandProperty Path
        }

        foreach ($item in $paths) {
            [pscustomobject][ordered]@{
                PSTypeName = 'PoshBot.File.Upload'
                Path = $item
                Title = $Title
                DM = ($PSBoundParameters.ContainsKey('DM') -and $DM)
            }
        }
    }
}

Export-ModuleMember -Function 'New-PoshBotFileUpload'
