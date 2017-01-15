
function New-PoshBotCardResponse {
    [cmdletbinding(DefaultParameterSetName = 'normal')]
    param(
        [ValidateSet('Normal', 'Warning', 'Error')]
        [string]$Type = 'Normal',

        [parameter(ParameterSetName = 'private')]
        [switch]$Private,

        [parameter(ParameterSetName = 'dm')]
        [switch]$DM,

        [parameter(ParameterSetName = 'normal')]
        [parameter(ParameterSetName = 'dm')]
        [parameter(ParameterSetName = 'private')]
        [string]$Text = [string]::empty,

        [parameter(ParameterSetName = 'normal')]
        [parameter(ParameterSetName = 'dm')]
        [parameter(ParameterSetName = 'private')]
        [string]$Title,

        [parameter(ParameterSetName = 'normal')]
        [parameter(ParameterSetName = 'dm')]
        [parameter(ParameterSetName = 'private')]
        [ValidateScript({
            $uri = $null
            if ([system.uri]::TryCreate($_, [System.UriKind]::Absolute, [ref]$uri)) {
                return $true
            } else {
                $msg = 'ThumbnailUrl must be a valid URL'
                throw [System.Management.Automation.ValidationMetadataException]$msg
            }
        })]
        [string]$ThumbnailUrl,

        [parameter(ParameterSetName = 'normal')]
        [parameter(ParameterSetName = 'dm')]
        [parameter(ParameterSetName = 'private')]
        [ValidateScript({
            $uri = $null
            if ([system.uri]::TryCreate($_, [System.UriKind]::Absolute, [ref]$uri)) {
                return $true
            } else {
                $msg = 'ImageUrl must be a valid URL'
                throw [System.Management.Automation.ValidationMetadataException]$msg
            }
        })]
        [string]$ImageUrl,

        [parameter(ParameterSetName = 'normal')]
        [parameter(ParameterSetName = 'dm')]
        [parameter(ParameterSetName = 'private')]
        [ValidateScript({
            $uri = $null
            if ([system.uri]::TryCreate($_, [System.UriKind]::Absolute, [ref]$uri)) {
                return $true
            } else {
                $msg = 'LinkUrl must be a valid URL'
                throw [System.Management.Automation.ValidationMetadataException]$msg
            }
        })]
        [string]$LinkUrl,

        [parameter(ParameterSetName = 'normal')]
        [parameter(ParameterSetName = 'dm')]
        [parameter(ParameterSetName = 'private')]
        [hashtable]$Fields,

        [ValidateScript({
            if ($_ -match '^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$') {
                return $true
            } else {
                $msg = 'Color but be a valid hexidecimal color code e.g. ##008000'
                throw [System.Management.Automation.ValidationMetadataException]$msg
            }
        })]
        [string]$Color = '#D3D3D3'
    )

    $response = [ordered]@{
        PSTypeName = 'PoshBot.Card.Response'
        Text = $Text
        Private = $PSBoundParameters.ContainsKey('Private')
        DM = $PSBoundParameters.ContainsKey('DM')
    }
    if ($PSBoundParameters.ContainsKey('Title')) {
        $response.Title = $Title
    }
    if ($PSBoundParameters.ContainsKey('ThumbnailUrl')) {
        $response.ThumbnailUrl = $ThumbnailUrl
    }
    if ($PSBoundParameters.ContainsKey('ImageUrl')) {
        $response.ImageUrl = $ImageUrl
    }
    if ($PSBoundParameters.ContainsKey('LinkUrl')) {
        $response.LinkUrl = $LinkUrl
    }
    if ($PSBoundParameters.ContainsKey('Fields')) {
        $response.Fields = $Fields
    }
    if ($PSBoundParameters.ContainsKey('Color')) {
        $response.Color = $Color
    } else {
        switch ($Type) {
            'Normal' {
                $response.Color = '#008000'
            }
            'Warning' {
                $response.Color = '#FFA500'
            }
            'Error' {
                $response.Color = '#FF0000'
            }
        }
    }

    $response = [pscustomobject]$response
    $response
}
