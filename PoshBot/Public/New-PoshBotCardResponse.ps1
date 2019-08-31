
function New-PoshBotCardResponse {
    <#
    .SYNOPSIS
        Tells PoshBot to send a specially formatted response.
    .DESCRIPTION
        Responses from PoshBot commands can either be plain text or formatted. Returning a response with New-PoshBotRepsonse will tell PoshBot
        to craft a specially formatted message when sending back to the chat network.
    .PARAMETER Type
        Specifies a preset color for the card response. If the [Color] parameter is specified as well, it will override this parameter.

        | Type    | Color  | Hex code |
        |---------|--------|----------|
        | Normal  | Greed  | #008000  |
        | Warning | Yellow | #FFA500  |
        | Error   | Red    | #FF0000  |
    .PARAMETER Text
        The text response from the command.
    .PARAMETER DM
        Tell PoshBot to redirect the response to a DM channel.
    .PARAMETER Title
        The title of the response. This will be the card title in chat networks like Slack.
    .PARAMETER ThumbnailUrl
        A URL to a thumbnail image to display in the card response.
    .PARAMETER ImageUrl
        A URL to an image to display in the card response.
    .PARAMETER LinkUrl
        Will turn the title into a hyperlink
    .PARAMETER Fields
        A hashtable to display as a table in the card response.
    .PARAMETER COLOR
        The hex color code to use for the card response. In Slack, this will be the color of the left border in the message attachment.
    .PARAMETER CustomData
        Any additional custom data you'd like to pass on. Useful for custom backends, in case you want to pass a specifically formatted response
        in the Data stream of the responses received by the backend. Any data sent here will be skipped by the built-in backends provided with PoshBot itself.
    .EXAMPLE
        function Do-Something {
            [cmdletbinding()]
            param(
                [parameter(mandatory)]
                [string]$MyParam
            )

            New-PoshBotCardResponse -Type Normal -Text 'OK, I did something.' -ThumbnailUrl 'https://www.streamsports.com/images/icon_green_check_256.png'
        }

        Tells PoshBot to send a formatted response back to the chat network. In Slack for example, this response will be a message attachment
        with a green border on the left, some text and a green checkmark thumbnail image.
    .EXAMPLE
        function Do-Something {
            [cmdletbinding()]
            param(
                [parameter(mandatory)]
                [string]$ComputerName
            )

            $info = Get-ComputerInfo -ComputerName $ComputerName -ErrorAction SilentlyContinue
            if ($info) {
                $fields = [ordered]@{
                    Name = $ComputerName
                    OS = $info.OSName
                    Uptime = $info.Uptime
                    IPAddress = $info.IPAddress
                }
                New-PoshBotCardResponse -Type Normal -Fields $fields
            } else {
                New-PoshBotCardResponse -Type Error -Text 'Something bad happended :(' -ThumbnailUrl 'http://p1cdn05.thewrap.com/images/2015/06/don-draper-shrug.jpg'
            }
        }

        Attempt to retrieve some information from a given computer and return a card response back to PoshBot. If the command fails for some reason,
        return a card response specified the error and a sad image.
    .OUTPUTS
        PSCustomObject
    .LINK
        New-PoshBotTextResponse
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope='Function', Target='*')]
    [cmdletbinding()]
    param(
        [ValidateSet('Normal', 'Warning', 'Error')]
        [string]$Type = 'Normal',

        [switch]$DM,

        [string]$Text = [string]::empty,

        [string]$Title,

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

        [System.Collections.IDictionary]$Fields,

        [ValidateScript({
            if ($_ -match '^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$') {
                return $true
            } else {
                $msg = 'Color but be a valid hexidecimal color code e.g. ##008000'
                throw [System.Management.Automation.ValidationMetadataException]$msg
            }
        })]
        [string]$Color = '#D3D3D3',

        [object]$CustomData
    )

    $response = [ordered]@{
        PSTypeName = 'PoshBot.Card.Response'
        Type = $Type
        Text = $Text.Trim()
        Private = $PSBoundParameters.ContainsKey('Private')
        DM = $PSBoundParameters['DM']
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
    if ($PSBoundParameters.ContainsKey('CustomData')) {
        $response.CustomData = $CustomData
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

    [pscustomobject]$response
}

Export-ModuleMember -Function 'New-PoshBotCardResponse'
