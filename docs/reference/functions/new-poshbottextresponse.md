
# New-PoshBotTextResponse

## SYNOPSIS

Tells PoshBot to handle the text response from a command in a special way.

## DESCRIPTION

Responses from PoshBot commands can be sent back to the channel they were posted from (default) or redirected to a DM channel with the calling user.
This could be useful if the contents the bot command returns are sensitive and should be be visible to all users in the channel.

## PARAMETERS

### Text

The text response from the command.

### DM

Tell PoshBot to redirect the response to a DM channel.

## EXAMPLES

### EXAMPLE 1

When Get-Foo is executed by PoshBot, the text response will be sent back to the calling user as a DM rather than back in the channel the command was called from.
This could be useful if the contents the bot command returns are sensitive and should be be visible to all users in the channel.

```powershell
function Get-Foo {
    [cmdletbinding()]
    param(
        [parameter(mandatory)]
        [string]$MyParam
    )

    New-PoshBotTextResponse -Text $MyParam -DM
}
```

## INPUTS

String

## OUTPUTS

PSCustomObject
