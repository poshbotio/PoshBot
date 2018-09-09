
function Get-MyCommands {
    <#
    .SYNOPSIS
        Returns all commands that the user is authorized to execute.
    .EXAMPLE
        !get-mycommands

        Returns all authorized commands.
    #>
    [PoshBot.BotCommand(
        Aliases = ('mycommands')
    )]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot
    )

    $myCommands = $Bot.PluginManager.Commands.GetEnumerator().ForEach({
        if ($_.Value.IsAuthorized($global:PoshBotContext.From, $Bot.RoleManager)) {
            $arrPlgCmdVer = $_.Name.Split(':')
            $plugin  = $arrPlgCmdVer[0]
            $command = $arrPlgCmdVer[1]
            $version = $arrPlgCmdVer[2]
            [pscustomobject]@{
                FullCommandName = "$plugin`:$command"
                Aliases         = ($_.Value.Aliases -join ', ')
                Type            = $_.Value.TriggerType.ToString()
                Version         = $version
            }
        }
    }) | Sort-Object -Property FullCommandName

    $text = ($myCommands | Format-Table -AutoSize | Out-String)
    New-PoshBotTextResponse -Text $text -AsCode
}
