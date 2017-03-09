
# New-PoshBotCardResponse

## SYNOPSIS

Tells PoshBot to send a specially formatted response.

## DESCRIPTION

Responses from PoshBot commands can either be plain text or formatted.
Returning a response with New-PoshBotRepsonse will tell PoshBot to craft a specially formatted message when sending back to the chat network.

## PARAMETERS

### Type

Specifies a preset color for the card response.
If the [Color] parameter is specified as well, it will override this parameter.

Type      Color    Hex code
---------------------------
Normal  = Greed  = #008000
Warning = Yellow = #FFA500
Error   = Red    = #FF0000

### Text

The text response from the command.

### DM

Tell PoshBot to redirect the response to a DM channel.

### Title

The title of the response.
This will be the card title in chat networks like Slack.

### ThumbnailUrl

A URL to a thumbnail image to display in the card response.

### ImageUrl

A URL to an image to display in the card response.

### LinkUrl

Will turn the title into a hyperlink

### Fields

A hashtable to display as a table in the card response.

### COLOR

The hex color code to use for the card response.
In Slack, this will be the color of the left border in the message attachment.

## EXAMPLES

### EXAMPLE 1

Tells PoshBot to send a formatted response back to the chat network.
In Slack for example, this response will be a message attachment with a green border on the left, some text and a green checkmark thumbnail image.

```powershell
function Do-Something {
    [cmdletbinding()]
    param(
        [parameter(mandatory)]
        [string]$MyParam
    )

    New-PoshBotCardResponse -Type Normal -Text 'OK, I did something.' -ThumbnailUrl 'https://www.streamsports.com/images/icon_green_check_256.png'
}
```

### EXAMPLE 2

Attempt to retrieve some information from a given computer and return a card response back to PoshBot.
If the command fails for some reason, return a card response specified the error and a sad image.

```powershell
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
```

## OUTPUTS

PSCustomObject
