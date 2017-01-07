
function Random {
    <#
    .SYNOPSIS
        Get a random number
    .EXAMPLE
        !random
    .EXAMPLE
        !random -min 42 -Max 8675309
    #>
    [cmdletbinding()]
    param(
        [int]$Min = 1,
        [int]$Max = 100
    )

    Get-Random -Minimum $min -Maximum $Max
}

function Insult {
    <#
    .SYNOPSIS
        Send a random insult to someone
    .EXAMPLE
        !insult -who 'bob'
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

function RandomFact {
    <#
    .SYNOPSIS
        Gets a random fact
    .EXAMPLE
        !randomfact
    .Role
        Demo
    #>
    [cmdletbinding()]
    param()

    $html = Invoke-WebRequest -Uri 'http://www.randomfunfacts.com/'
    $fact = $html.ParsedHtml.getElementById('AutoNumber1').textContent
    return $fact
}

function RandomJoke {
    <#
    .SYNOPSIS
        Gets a random joke
    .EXAMPLE
        !randomjoke
    .Role
        Demo
    #>
    [cmdletbinding()]
    param()

    $html = Invoke-WebRequest -Uri 'http://www.randomfunnyjokes.com/'
    $joke = $html.ParsedHtml.getElementById('AutoNumber1').textContent
    return $joke
}

function RandomQuote {
    <#
    .SYNOPSIS
        Gets a quote from a famous person
    .EXAMPLE
        !randomquote
    .Role
        Demo
    #>
    [cmdletbinding()]
    param()

    $html = Invoke-WebRequest -Uri 'http://www.quotability.com/'
    $quote = $html.ParsedHtml.getElementById('AutoNumber1').textContent
    return $quote
}
