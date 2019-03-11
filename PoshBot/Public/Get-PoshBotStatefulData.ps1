
function Get-PoshBotStatefulData {
    <#
    .SYNOPSIS
        Get stateful data previously exported from a PoshBot command
    .DESCRIPTION
        Get stateful data previously exported from a PoshBot command

        Reads data from the PoshBot ConfigurationDirectory.
    .PARAMETER Name
        If specified, retrieve only this property from the stateful data
    .PARAMETER ValueOnly
        If specified, return only the value of the specified property Name
    .PARAMETER Scope
        Get stateful data from this scope:
            Module: Data scoped to this plugin
            Global: Data available to any Poshbot plugin
    .EXAMPLE
        $ModuleData = Get-PoshBotStatefulData

        Get all stateful data for the PoshBot plugin this runs from
    .EXAMPLE
        $Something = Get-PoshBotStatefulData -Name 'Something' -ValueOnly -Scope Global

        Set $Something to the value of the 'Something' property from Poshbot's global stateful data
    .LINK
        Set-PoshBotStatefulData
    .LINK
        Remove-PoshBotStatefulData
    .LINK
        Start-PoshBot
    #>
    [cmdletbinding()]
    param(
        [string]$Name = '*',

        [switch]$ValueOnly,

        [validateset('Global','Module')]
        [string]$Scope = 'Module'
    )
    process {
        if($Scope -eq 'Module') {
            $FileName = "$($global:PoshBotContext.Plugin).state"
        } else {
            $FileName = "PoshbotGlobal.state"
        }
        $Path = Join-Path $global:PoshBotContext.ConfigurationDirectory $FileName

        if(-not (Test-Path $Path)) {
            Write-Verbose "Requested stateful data file not found: [$Path]"
            return
        }
        Write-Verbose "Getting stateful data from [$Path]"
        $Output = Import-Clixml -Path $Path | Select-Object -Property $Name
        if($ValueOnly)
        {
            $Output = $Output.${Name}
        }
        $Output
    }
}

Export-ModuleMember -Function 'Get-PoshBotStatefulData'
