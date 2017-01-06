
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
    foreach ($pluginKey in $Bot.PluginManager.Plugins.Keys) {
        $plugin = $Bot.PluginManager.Plugins[$pluginKey]
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

    if ($Bot._Stopwatch.IsRunning) {
        $uptime = $Bot._Stopwatch.Elapsed.ToString()
    } else {
        $uptime = $null
    }
    $hash = [ordered]@{
        Version = '1.0.0'
        Uptime = $uptime
        Plugins = $Bot.PluginManager.Plugins.Count
        Commands = $Bot.PluginManager.Commands.Count
    }

    $status = [pscustomobject]$hash
    $status
}

function Roles {
    <#
    .SYNOPSIS
        Get all roles
    .EXAMPLE
        !roles
    #>
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot
    )

    $roles = New-Object System.Collections.ArrayList
    foreach ($key in ($Bot.RoleManager.Roles.Keys | Sort-Object)) {
        [pscustomobject][ordered]@{
            Name = $key
            Description =$Bot.RoleManager.Roles[$key].Description
        }
    }
}

function About {
    [cmdletbinding()]
    param()

    $path = "$PSScriptRoot/../../PoshBot.psd1"
    #$manifest = Test-ModuleManifest -Path $path -Verbose:$false
    $manifest = Import-PowerShellDataFile -Path $path
    $ver = $manifest.ModuleVersion

    $msg = @"
PoshBot v$ver
$($manifest.CopyRight)

https://github.com/devblackops/PoshBot
"@
    $msg
}

Export-ModuleMember -Function *
