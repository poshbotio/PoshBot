---
external help file: PoshBot-help.xml
Module Name: poshbot
online version:
schema: 2.0.0
---

# New-PoshBotTextResponse

## SYNOPSIS
Tells PoshBot to handle the text response from a command in a special way.

## SYNTAX

```
New-PoshBotTextResponse [-Text] <String[]> [-AsCode] [-DM] [<CommonParameters>]
```

## DESCRIPTION
Responses from PoshBot commands can be sent back to the channel they were posted from (default) or redirected to a DM channel with the
calling user.
This could be useful if the contents the bot command returns are sensitive and should not be visible to all users
in the channel.

## EXAMPLES

### EXAMPLE 1
```
function Get-Foo {
```

\[cmdletbinding()\]
    param(
        \[parameter(mandatory)\]
        \[string\]$MyParam
    )

    New-PoshBotTextResponse -Text $MyParam -DM
}

When Get-Foo is executed by PoshBot, the text response will be sent back to the calling user as a DM rather than back in the channel the
command was called from.
This could be useful if the contents the bot command returns are sensitive and should not be visible to all users
in the channel.

## PARAMETERS

### -Text
The text response from the command.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -AsCode
Format the text in a code block if the backend supports it.

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### String
## OUTPUTS

### PSCustomObject
## NOTES

## RELATED LINKS

[New-PoshBotCardResponse]()

