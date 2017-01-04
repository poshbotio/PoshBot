
function Help {
    <#
    .SYNOPSIS
        List bot commands
    .EXAMPLE
        !help mycommand
    #>
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [string]$Filter
    )

    #Write-Output ($bot | format-list | out-string)

    $availableCommands = New-Object System.Collections.ArrayList
    foreach ($pluginKey in $Bot.Plugins.Keys) {
        $plugin = $Bot.Plugins[$pluginKey]
        foreach ($commandKey in $plugin.Commands.Keys) {
            $command = $plugin.Commands[$commandKey]
            $x = [pscustomobject][ordered]@{
                Command = "$pluginKey`:$CommandKey"
                #Plugin = $pluginKey
                #Name = $commandKey
                Description = $command.Description
                HelpText = $command.HelpText
            }
            $availableCommands.Add($x) | Out-Null
        }
    }

    # If we asked for help about a particular plugin or command, filter on it
    if ($PSBoundParameters.ContainsKey('Filter')) {
        $availableCommands = $availableCommands.Where({($_.Plugin -like $Filter) -or ($_.Name -like $Filter)})
    }

    Write-Output ($availableCommands | Format-Table -AutoSize | Out-String -Width 150)
}

function Status {
    <#
    .SYNOPSIS
        Get Bot status
    .EXAMPLE
        !status
    #>
    param(
        [parameter(Mandatory)]
        $Bot
    )

    if ($Bot.Stopwatch.IsRunning) {
        $uptime = $Bot.Stopwatch.Elapsed.ToString()
    } else {
        $uptime = $null
    }
    $hash = [ordered]@{
        Version = '1.0.0'
        Uptime = $uptime
        Plugins = $Bot.Plugins.Count
        Commands = $Bot.Commands.Count
    }

    $status = [pscustomobject]$hash
    $status
}

Export-ModuleMember -Function *
