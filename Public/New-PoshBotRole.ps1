
function New-PoshBotRole {
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        [string]$Name,

        [ValidateNotNullOrEmpty]
        [string]$Description
    )

    $r = [Role]::new($Name)

    if ($PSBoundParameters.ContainsKey('Description')) {
        $r.Description = $Description
    }

    $r
}
