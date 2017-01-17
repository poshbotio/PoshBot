
function New-PoshBotInstance {
    [cmdletbinding(DefaultParameterSetName = 'path')]
    param(
        [parameter(Mandatory, ParameterSetName = 'path')]
        [string]$Name,

        [parameter(Mandatory)]
        [Backend]$Backend,

        [parameter(ParameterSetName = 'path')]
        [string]$ConfigurationPath = (Join-Path -Path (Join-Path -Path $env:USERPROFILE -ChildPath '.poshbot') -ChildPath 'PoshBot.psd1'),

        [parameter(ParameterSetName = 'config')]
        [BotConfiguration]$Configuration
    )

    $here = $script:moduleRoot

    if ($PSCmdlet.ParameterSetName -eq 'path') {
        Write-Verbose -Message "Creating bot instance from data file [$ConfigurationPath]"
        [Bot]::new($Name, $Backend, $here, $ConfigurationPath)
    } elseIf ($PSCmdlet.ParameterSetName -eq 'config') {
        Write-Verbose -Message 'Creating bot instance from configuration object'
        [Bot]::new($Backend, $here, $Configuration)
    }
}
