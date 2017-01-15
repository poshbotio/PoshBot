
function New-PoshBotTextResponse {
    [cmdletbinding(DefaultParameterSetName = 'normal')]
    param(
        [parameter(Mandatory, ParameterSetName = 'normal')]
        [parameter(Mandatory, ParameterSetName = 'private')]
        [parameter(Mandatory, ParameterSetName = 'dm')]
        [string]$Text,

        [parameter(ParameterSetName = 'private')]
        [switch]$Private,

        [parameter(ParameterSetName = 'dm')]
        [switch]$DM
    )

    $response = [ordered]@{
        PSTypeName = 'PoshBot.Text.Response'
        Text = $Text
        Private = $PSBoundParameters.ContainsKey('Private')
        DM = $PSBoundParameters.ContainsKey('DM')
    }

    $response = [pscustomobject]$response
    $response
}
