
function New-PoshBotTextResponse {
    <#
    .SYNOPSIS
        Tells PoshBot to handle the text response from a command in a special way.
    .DESCRIPTION
        Responses from PoshBot commands can be sent back to the channel they were posted from (default) or redirected to a DM channel with the
        calling user. This could be useful if the contents the bot command returns are sensitive and should not be visible to all users
        in the channel.
    .PARAMETER Text
        The text response from the command.
    .PARAMETER AsCode
        Format the text in a code block if the backend supports it.
    .PARAMETER DM
        Tell PoshBot to redirect the response to a DM channel.
    .EXAMPLE
        function Get-Foo {
            [cmdletbinding()]
            param(
                [parameter(mandatory)]
                [string]$MyParam
            )

            New-PoshBotTextResponse -Text $MyParam -DM
        }

        When Get-Foo is executed by PoshBot, the text response will be sent back to the calling user as a DM rather than back in the channel the
        command was called from. This could be useful if the contents the bot command returns are sensitive and should not be visible to all users
        in the channel.
    .INPUTS
        String
    .OUTPUTS
        PSCustomObject
    .LINK
        New-PoshBotCardResponse
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope='Function', Target='*')]
    [cmdletbinding()]
    param(
        [parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]]$Text,

        [switch]$AsCode,

        [switch]$DM,

        [switch]$TH
    )

    process {
        foreach ($item in $text) {
            [pscustomobject][ordered]@{
                PSTypeName = 'PoshBot.Text.Response'
                Text = $item.Trim()
                AsCode = $PSBoundParameters.ContainsKey('AsCode')
                DM = $PSBoundParameters.ContainsKey('DM')
                TH = $PSBoundParameters.ContainsKey('TH')
            }
        }
    }
}

Export-ModuleMember -Function 'New-PoshBotTextResponse'
