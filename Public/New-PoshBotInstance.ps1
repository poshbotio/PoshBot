
function New-PoshBotInstance {
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        [string]$Name,

        [Backend]$Backend,

        [string]$ConfigurationDirectory = (Join-Path -Path $env:USERPROFILE -ChildPath '.poshbot')
    )
    $here = $script:moduleRoot
    [Bot]::new($Name, $Backend, $here, $ConfigurationDirectory)
}
