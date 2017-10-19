
# Adding Help to functions

You will probably have a lot of commands loaded in PoshBot and most likely will not remember every single one and their parameters.
Luckily, PowerShell has a pretty good [Comment-based help](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_comment_based_help?view=powershell-5.1) system so PoshBot leverages this functionality to provide meaningful help to commands inside a chat window.

In order to make the help system useful within Poshbot, Your plugin commands should at a minimum have comment-based help that includes a `Synopsis` and at least one `Example` section. The `Parameter` section is recommended but not required.

```powershell
function Invoke-HelloWorld {
    <#
    .SYNOPSIS
    Say hello
    .PARAMETER Name
    The person to say hello to
    .EXAMPLE
    !invoke-helloworld Brandon
    #>
    [PoshBot.BotCommand()]
    [cmdletbinding()]
    param(
        [string]$Name = 'Anonymous'
    )

    Write-Output "Hi $Name!"
}
```

You can use the builtin command `help` to ... wait for it... get help about available commands.
The `help` command has a few parameters to enable getting help on certain commands or to control the level of detail shown.


List all available commands

```
!help
```

List help and filter anything that has the word `azure` in it.

```
!help azure
```

List all regex type commands
```
!help -type regex
```

List all event type commands
```
!help -type event
```

Get detailed help for the `mycommand` command.
```
!help myplugin:mycommand -detailed
```
