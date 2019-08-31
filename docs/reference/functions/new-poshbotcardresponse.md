---
external help file: PoshBot-help.xml
Module Name: poshbot
online version:
schema: 2.0.0
---

# New-PoshBotCardResponse

## SYNOPSIS
Tells PoshBot to send a specially formatted response.

## SYNTAX

```
New-PoshBotCardResponse [[-Type] <String>] [-DM] [[-Text] <String>] [[-Title] <String>]
 [[-ThumbnailUrl] <String>] [[-ImageUrl] <String>] [[-LinkUrl] <String>] [[-Fields] <IDictionary>]
 [[-Color] <String>] [[-CustomData] <Object>] [<CommonParameters>]
```

## DESCRIPTION
Responses from PoshBot commands can either be plain text or formatted.
Returning a response with New-PoshBotRepsonse will tell PoshBot
to craft a specially formatted message when sending back to the chat network.

## EXAMPLES

### EXAMPLE 1
```
function Do-Something {
```

\[cmdletbinding()\]
    param(
        \[parameter(mandatory)\]
        \[string\]$MyParam
    )

    New-PoshBotCardResponse -Type Normal -Text 'OK, I did something.' -ThumbnailUrl 'https://www.streamsports.com/images/icon_green_check_256.png'
}

Tells PoshBot to send a formatted response back to the chat network.
In Slack for example, this response will be a message attachment
with a green border on the left, some text and a green checkmark thumbnail image.

### EXAMPLE 2
```
function Do-Something {
```

\[cmdletbinding()\]
    param(
        \[parameter(mandatory)\]
        \[string\]$ComputerName
    )

    $info = Get-ComputerInfo -ComputerName $ComputerName -ErrorAction SilentlyContinue
    if ($info) {
        $fields = \[ordered\]@{
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

Attempt to retrieve some information from a given computer and return a card response back to PoshBot.
If the command fails for some reason,
return a card response specified the error and a sad image.

## PARAMETERS

### -Type
Specifies a preset color for the card response.
If the \[Color\] parameter is specified as well, it will override this parameter.

| Type    | Color  | Hex code |
|---------|--------|----------|
| Normal  | Greed  | #008000  |
| Warning | Yellow | #FFA500  |
| Error   | Red    | #FF0000  |

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: Normal
Accept pipeline input: False
Accept wildcard characters: False
```

### -DM
Tell PoshBot to redirect the response to a DM channel.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Text
The text response from the command.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: [string]::empty
Accept pipeline input: False
Accept wildcard characters: False
```

### -Title
The title of the response.
This will be the card title in chat networks like Slack.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ThumbnailUrl
A URL to a thumbnail image to display in the card response.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ImageUrl
A URL to an image to display in the card response.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LinkUrl
Will turn the title into a hyperlink

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Fields
A hashtable to display as a table in the card response.

```yaml
Type: IDictionary
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Color
The hex color code to use for the card response.
In Slack, this will be the color of the left border in the message attachment.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 8
Default value: #D3D3D3
Accept pipeline input: False
Accept wildcard characters: False
```

### -CustomData
Any additional custom data you'd like to pass on.
Useful for custom backends, in case you want to pass a specifically formatted response
in the Data stream of the responses received by the backend.
Any data sent here will be skipped by the built-in backends provided with PoshBot itself.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 9
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### PSCustomObject
## NOTES

## RELATED LINKS

[New-PoshBotTextResponse]()

