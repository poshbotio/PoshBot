
function Random {
    <#
    .SYNOPSIS
        Get a random thing
    .EXAMPLE
        !random
    #>
    [cmdletbinding()]
    param()

    Write-Output "A random what?"
    Write-Output "Sub commands:"
    Write-Output "random insult`nrandom fact`nrandom joke`nrandom quote"
}

function Random-number {
    <#
    .SYNOPSIS
        Get a random number
    .EXAMPLE
        !random number
    .EXAMPLE
        !random number -min 42 -Max 8675309
    #>
    [cmdletbinding()]
    param(
        [int]$Min = 1,
        [int]$Max = 100
    )

    Get-Random -Minimum $min -Maximum $Max
}

function Random-Insult {
    <#
    .SYNOPSIS
        Send a random insult to someone
    .EXAMPLE
        !random insult -who 'bob'
    .Role
        Demo
    #>
    [cmdletbinding()]
    param(
        [string]$Who
    )

    $html = Invoke-WebRequest -Uri 'http://www.randominsults.net/'
    $insult = $html.ParsedHtml.getElementById('AutoNumber1').textContent

    if ($PSBoundParameters.ContainsKey('Who')) {
        $who = $who.TrimStart('@')
        Write-Output "Hey @$Who! $insult"
    } else {
        Write-Output $insult
    }
}

function Random-Fact {
    <#
    .SYNOPSIS
        Gets a random fact
    .EXAMPLE
        !random fact
    .Role
        Demo
    #>
    [cmdletbinding()]
    param()

    $html = Invoke-WebRequest -Uri 'http://www.randomfunfacts.com/'
    $fact = $html.ParsedHtml.getElementById('AutoNumber1').textContent
    return $fact
}

function Random-Joke {
    <#
    .SYNOPSIS
        Gets a random joke
    .EXAMPLE
        !random joke
    .Role
        Demo
    #>
    [cmdletbinding()]
    param()

    $html = Invoke-WebRequest -Uri 'http://www.randomfunnyjokes.com/'
    $joke = $html.ParsedHtml.getElementById('AutoNumber1').textContent
    return $joke
}

function Random-Quote {
    <#
    .SYNOPSIS
        Gets a quote from a famous person
    .EXAMPLE
        !random quote
    .Role
        Demo
    #>
    [cmdletbinding()]
    param()

    $html = Invoke-WebRequest -Uri 'http://www.quotability.com/'
    $quote = $html.ParsedHtml.getElementById('AutoNumber1').textContent
    return $quote
}

function Giphy {
    <#
    .SYNOPSIS
        Search Giphy
    .EXAMPLE
        !giphy --search 'cats'
    .EXAMPLE
        !giphy --trending
    .Role
        Demo
    #>
    [cmdletbinding(DefaultParameterSetName = 'search')]
    param(
        [parameter(Mandatory, ParameterSetName = 'search')]
        [string]$Search,

        [parameter(Mandatory, ParameterSetName = 'trending')]
        [switch]$Trending,

        [ValidateRange(1, 10)]
        [int]$Number = 1
    )

    $apiKey = 'dc6zaTOxFJmzC'

    if ($PSCmdlet.ParameterSetName -eq 'search') {
        $d = Invoke-RestMethod -Uri "http://api.giphy.com/v1/gifs/search?q=$Search&limit=25&api_key=$apiKey" -UseBasicParsing -UseDefaultCredentials
    } elseif ($PSCmdlet.ParameterSetName -eq 'trending') {
        $d = Invoke-RestMethod -Uri "http://api.giphy.com/v1/gifs/trending?limit=25&api_key=$apiKey" -UseBasicParsing -UseDefaultCredentials
    }
    if ($d.data) {
        $url = ($d.data | Get-Random -Count $Number).images.downsized.url
        Write-Output $url
    } else {
        Write-Output 'No results found'
    }
}