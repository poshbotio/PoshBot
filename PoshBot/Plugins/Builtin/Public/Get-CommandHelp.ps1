
function Get-CommandHelp {
    <#
    .SYNOPSIS
        Show details and help information about bot commands.
    .PARAMETER Filter
        The text to filter available commands and plugins on.
    .PARAMETER Detailed
        Show more detailed help information for the command.
    .PARAMETER Type
        Only return commands of specified type.
    .EXAMPLE
        !help --filter new-group

        Get help on the 'New-Group' command.
    .EXAMPLE
        !help new-group --detailed

        Get detailed help on the 'New-group' command
    .EXAMPLE
        !help --type regex

        List all commands with the [regex] trigger type.
    #>
    [PoshBot.BotCommand(
        Aliases = ('man', 'help')
    )]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Position = 0)]
        [string]$Filter,

        [switch]$Detailed,

        [ValidateSet('*', 'Command', 'Event', 'Regex')]
        [string]$Type = '*'
    )

    $allCommands = $Bot.PluginManager.Commands.GetEnumerator() |
        Where-Object {$_.Value.TriggerType -like $Type} |
        Foreach-Object {
            $arrPlgCmdVer = $_.Name.Split(':')
            $plugin = $arrPlgCmdVer[0]
            $command = $arrPlgCmdVer[1]
            $version = $arrPlgCmdVer[2]
            [pscustomobject]@{
                FullCommandName = "$plugin`:$command"
                Command = $command
                Type = $_.Value.TriggerType.ToString()
                Aliases = ($_.Value.Aliases -join ', ')
                Plugin = $plugin
                Version = $version
                Description = $_.Value.Description
                Usage = ($_.Value.Usage | Format-List | Out-string).Trim()
                Enabled = $_.Value.Enabled.ToString()
                Permissions = ($_.Value.AccessFilter.Permissions.Keys | Format-List | Out-string).Trim()
            }
    }

    $respParams = @{
        Type = 'Normal'
    }

    $result = @()
    if ($PSBoundParameters.ContainsKey('Filter')) {
        $respParams.Title = "Commands matching [$Filter]"
        $result = @($allCommands | Where-Object {
            ($_.FullCommandName -like "*$Filter*") -or
            ($_.Command -like "*$Filter*") -or
            ($_.Plugin -like "*$Filter*") -or
            ($_.Version -like "*$Filter*") -or
            ($_.Description -like "*$Filter*") -or
            ($_.Usage -like "*$Filter*") -or
            ($_.Aliases -like "*$Filter*")
        })
    } else {
        $respParams.Title = 'All commands'
        $result = $allCommands
    }
    $result = $result | Sort-Object -Property FullCommandName

    if ($result) {
        if ($result.Count -ge 1) {
            $fields = @(
                'FullCommandName'
                @{l='Aliases';e={$_.Aliases -join ', '}}
                @{l='Type';e={$_.Type}}
                'Version'
            )
            $respParams.Text = ($result | Select-Object -Property $fields | Out-String)
        } else {
            if ($Detailed) {
                $fullVersionName = "$($result.FullCommandName)`:$($result.Version)"
                $manString = ($Bot.PluginManager.Commands[$fullVersionName] | Get-Help -Detailed | Out-String)
                $result | Add-Member -MemberType NoteProperty -Name Manual -Value "`n$manString"
            }
            $respParams.Text = ($result | Format-List | Out-String -Width 150).Trim()
        }

        New-PoshBotTextResponse -Text $respParams.Text -AsCode
    } else {
        New-PoshBotCardResponse -Type Warning -Text "No commands found matching [$Filter] :(" -Title 'Rut row' -ThumbnailUrl $thumb.rutrow
    }
}
