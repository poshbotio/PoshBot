
function New-PoshBotPlugin {
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        [string]$Name,

        [Command[]]$Commands = @(),

        [Role[]]$Roles = @()
    )

    $plugin = [Plugin]::new($Name)
    $Commands | foreach {
        $plugin.AddCommand($_)
    }
    $Roles | foreach {
        $plugin.AddRole($_)
    }
    return $plugin
}
