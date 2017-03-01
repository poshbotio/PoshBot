
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
        !random number [--min 42] [--max 8675309]
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
        !random-insult [--who <bob>]
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
        !random-fact
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
        !random-joke
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
        !random-quote
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
        !giphy (--search 'cats' [--number 3] | --trending [--number 3])
    #>
    [cmdletbinding(DefaultParameterSetName = 'search')]
    param(
        [parameter(Mandatory, Position = 0, ParameterSetName = 'search')]
        [string]$Search,

        [parameter(Mandatory, Position = 0, ParameterSetName = 'trending')]
        [switch]$Trending,

        [parameter(Position = 1)]
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

function Roll-Dice {
    <#
    .SYNOPSIS
        Roll one or more (n) sided dice
    .EXAMPLE
        !roll-dice [--dice 2d20] [--bonus 5]
    #>
    [PoshBot.BotCommand(Permissions = 'dice-master')]
    [cmdletbinding()]
    param(
        [parameter(position = 0)]
        [string]$Dice = '2d20',

        [parameter(position = 1)]
        [int]$Bonus = 0
    )
    $quantity, $faces = $Dice -split 'd'
    $total = (1..$quantity | ForEach-Object {
        Get-Random -Minimum $quantity -Maximum ([int]$faces * 2)
    } | Measure-Object -Sum).Sum

    [pscustomobject]@{
        Bonus = [int]$bonus
        Total = ([int]$bonus + $total)
    }
}

function Shipit {
    <#
    .SYNOPSIS
        Display a motivational squirrel
    .EXAMPLE
        !shipit
    #>
    [PoshBot.BotCommand(
        Command = $false,
        CommandName = 'shipit',
        TriggerType = 'regex',
        Regex = 'shipit'
    )]
    [cmdletbinding()]
    param(
        [parameter(ValueFromRemainingArguments)]
        $Dummy
    )

    $squirrels = @(
        'http://28.media.tumblr.com/tumblr_lybw63nzPp1r5bvcto1_500.jpg',
        'http://i.imgur.com/DPVM1.png',
        'http://d2f8dzk2mhcqts.cloudfront.net/0772_PEW_Roundup/09_Squirrel.jpg',
        'http://www.cybersalt.org/images/funnypictures/s/supersquirrel.jpg',
        'http://www.zmescience.com/wp-content/uploads/2010/09/squirrel.jpg',
        'https://dl.dropboxusercontent.com/u/602885/github/sniper-squirrel.jpg',
        'http://1.bp.blogspot.com/_v0neUj-VDa4/TFBEbqFQcII/AAAAAAAAFBU/E8kPNmF1h1E/s640/squirrelbacca-thumb.jpg',
        'https://dl.dropboxusercontent.com/u/602885/github/soldier-squirrel.jpg',
        'https://dl.dropboxusercontent.com/u/602885/github/squirrelmobster.jpeg',
        'http://i.imgur.com/tIQluOd.jpg"',
        'http://i.imgur.com/PIQBHKA.jpg',
        'http://i.imgur.com/Qp8iF6l.jpg',
        'http://i.imgur.com/I7drYFb.jpg',
        'http://i.imgur.com/1obU7mz.jpg'
    )

    Write-Output $squirrels | Get-Random
}

function Cookies {
    <#
    .SYNOPSIS
        Respond to cookied
    #>
    [PoshBot.BotCommand(
        Command = $false,
        CommandName = 'cookies',
        TriggerType = 'regex',
        Regex = 'cookies'
    )]
    [cmdletbinding()]
    param(
        [parameter(ValueFromRemainingArguments)]
        $Dummy
    )

    Write-Output 'Did someone mention cookies? I love cookies! Nom Nom Nom!'
}

function ChannelTopicChange {
    <#
    .SYNOPSIS
        Responds to channel topic change events
    #>
    [PoshBot.BotCommand(
        Command = $false,
        TriggerType = 'event',
        MessageType = 'Message',
        MessageSubType = 'ChannelTopicChanged'
    )]
    [cmdletbinding()]
    param(
        [parameter(ValueFromRemainingArguments)]
        $Dummy
    )

    Write-Output 'I kind of liked the old topic'
}

function ChannelPurposeChange {
    <#
    .SYNOPSIS
        Responds to channel topic change events
    #>
    [PoshBot.BotCommand(
        Command = $false,
        TriggerType = 'event',
        MessageType = 'Message',
        MessageSubType = 'ChannelPurposeChanged'
    )]
    [cmdletbinding()]
    param(
        [parameter(ValueFromRemainingArguments)]
        $Dummy
    )

    Write-Output 'So we have a new purpose in live huh?'
}

function WelcomeUserToRoom {
    <#
    .SYNOPSIS
        Responds to channel join events with a friendly message
    #>
    [PoshBot.BotCommand(
        Command = $false,
        TriggerType = 'event',
        MessageType = 'Message',
        MessageSubType = 'ChannelJoined'
    )]
    [cmdletbinding()]
    param(
        [parameter(ValueFromRemainingArguments)]
        $Dummy
    )

    Write-Output 'Greetings! We were just talking about you.'
}

function SayGoodbyeTouser {
    <#
    .SYNOPSIS
        Say goodbye to a user when they leave a channel
    #>
    [PoshBot.BotCommand(
        Command = $false,
        TriggerType = 'event',
        MessageType = 'Message',
        MessageSubType = 'ChannelLeft'
    )]
    [cmdletbinding()]
    param(
        [parameter(ValueFromRemainingArguments)]
        $Dummy
    )

    Write-Output 'Good riddance. I never liked that person anyway.'
}

function GoldStar {
    <#
    .SYNOPSIS
        Say goodbye to a user when they leave a channel
    #>
    [PoshBot.BotCommand(
        Command = $false,
        TriggerType = 'event',
        MessageType = 'StarAdded'
    )]
    [cmdletbinding()]
    param(
        [parameter(ValueFromRemainingArguments)]
        $Dummy
    )

    Write-Output 'Hey everyone look! Someone got a gold star :)'
}

function Start-LongRunningCommand {
    <#
    .SYNOPSIS
        Start a long running command
    .EXAMPLE
        !start-longrunningcommand [--seconds 20]
    #>
    [cmdletbinding()]
    param(
        [parameter(position = 0)]
        [int]$Seconds = 10
    )

    Start-Sleep -Seconds $Seconds
    Write-Output "Comamnd finished after [$Seconds] seconds"
}

function Bad-Command {
    <#
    .SYNOPSIS
        Intentionally throws errors
    .EXAMPLE
        !bad-command
    #>
    [cmdletbinding()]
    param()

    Write-Error -Message "I'm error number one"
    Write-Error -Message "I'm error number two"
}

function WolframAlpha {
    <#
    .SYNOPSIS
        Asks Wolfram Alpha a question
    .EXAMPLE
        !wolframalpha '34th president of the united states'
    #>
    [cmdletbinding()]
    param(
        [PoshBot.FromConfig('WolframAlphaApiKey')]
        [parameter(Mandatory)]
        [string]$ApiKey,

        [parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )

    $q = $Arguments -join ' '
    $url = "http://api.wolframalpha.com/v1/result?i=$q&appid=$ApiKey"
    $r = Invoke-RestMethod -Uri $url
    Write-Output $r
}

function Get-Foo {
    <#
    .SYNOPSIS
        Gets parameter value from bot configuration
    .EXAMPLE
        !get-foo
    #>
    [cmdletbinding()]
    param(
        [PoshBot.FromConfig()]
        [parameter(Mandatory)]
        [string]$Config1
    )

    Write-Output "[$Config1] was passed in from bot configuration"
}
