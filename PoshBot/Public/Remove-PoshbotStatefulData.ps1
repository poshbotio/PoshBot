
function Remove-PoshBotStatefulData {
    <#
    .SYNOPSIS
        Remove existing stateful data
    .DESCRIPTION
        Remove existing stateful data
    .PARAMETER Name
        Property to remove from the stateful data file
    .PARAMETER Scope
        Sets the scope of stateful data to remove:
            Module: Remove stateful data from the current module's data
            Global: Remove stateful data from the global PoshBot data
    .PARAMETER Depth
        Specifies how many levels of contained objects are included in the XML representation. The default value is 2
    .EXAMPLE
        PS C:\> Remove-PoshBotStatefulData -Name 'ToUse'

        Removes the 'ToUse' property from stateful data for the PoshBot plugin you are currently running this from.
    .EXAMPLE
        PS C:\> Remove-PoshBotStatefulData -Name 'Something' -Scope Global

        Removes the 'Something' property from PoshBot's global stateful data
    .LINK
        Get-PoshBotStatefulData
    .LINK
        Set-PoshBotStatefulData
    .LINK
        Start-PoshBot
    #>
    [cmdletbinding(SupportsShouldProcess)]
    param(
        [parameter(Mandatory)]
        [string[]]$Name,

        [validateset('Global','Module')]
        [string]$Scope = 'Module',

        [int]$Depth = 2
    )
    process {
        if($Scope -eq 'Module') {
            $FileName = "$($global:PoshBotContext.Plugin).state"
        } else {
            $FileName = "PoshbotGlobal.state"
        }
        $Path = Join-Path $global:PoshBotContext.ConfigurationDirectory $FileName


        if(-not (Test-Path $Path)) {
            return
        } else {
            $ToWrite = Import-Clixml -Path $Path | Select-Object * -ExcludeProperty $Name
        }

        if ($PSCmdlet.ShouldProcess($Name, 'Remove stateful data')) {
            Export-Clixml -Path $Path -InputObject $ToWrite -Depth $Depth -Force
            Write-Verbose -Message "Stateful data [$Name] removed from [$Path]"
        }
    }
}

Export-ModuleMember -Function 'Remove-PoshBotStatefulData'
