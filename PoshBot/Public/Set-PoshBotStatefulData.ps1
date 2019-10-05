
function Set-PoshBotStatefulData {
    <#
    .SYNOPSIS
        Save stateful data to use in another PoshBot command
    .DESCRIPTION
        Save stateful data to use in another PoshBot command

        Stores data in clixml format, in the PoshBot ConfigurationDirectory.

        If <Name> property exists in current stateful data file, it is overwritten
    .PARAMETER Name
        Property to add to the stateful data file
    .PARAMETER Value
        Value to set for the Name property in the stateful data file
    .PARAMETER Scope
        Sets the scope of stateful data to set:
            Module: Allow only this plugin to access the stateful data you save
            Global: Allow any plugin to access the stateful data you save
    .PARAMETER Depth
        Specifies how many levels of contained objects are included in the XML representation. The default value is 2
    .EXAMPLE
        PS C:\> Set-PoshBotStatefulData -Name 'ToUse' -Value 'Later'

        Adds a 'ToUse' property to the stateful data for the PoshBot plugin you are currently running this from.
    .EXAMPLE
        PS C:\> $Anything | Set-PoshBotStatefulData -Name 'Something' -Scope Global

        Adds a 'Something' property to PoshBot's global stateful data, with the value of $Anything
    .LINK
        Get-PoshBotStatefulData
    .LINK
        Remove-PoshBotStatefulData
    .LINK
        Start-PoshBot
    #>
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Scope='Function', Target='*')]
    [cmdletbinding(SupportsShouldProcess)]
    param(
        [parameter(Mandatory)]
        [string]$Name,

        [parameter(ValueFromPipeline,
                   Mandatory)]
        [object[]]$Value,

        [validateset('Global','Module')]
        [string]$Scope = 'Module',

        [int]$Depth = 2
    )

    end {
        if ($Value.Count -eq 1) {
            $Value = $Value[0]
        }

        if($Scope -eq 'Module') {
            $FileName = "$($global:PoshBotContext.Plugin).state"
        } else {
            $FileName = "PoshbotGlobal.state"
        }
        $Path = Join-Path $global:PoshBotContext.ConfigurationDirectory $FileName

        if(-not (Test-Path $Path)) {
            $ToWrite = [pscustomobject]@{
                $Name = $Value
            }
        } else {
            $Existing = Import-Clixml -Path $Path
            # TODO: Consider handling for -Force?
            If($Existing.PSObject.Properties.Name -contains $Name) {
                Write-Verbose "Overwriting [$Name]`nCurrent value: [$($Existing.$Name | Out-String)])`nNew Value: [$($Value | Out-String)]"
            }
            Add-Member -InputObject $Existing -MemberType NoteProperty -Name $Name -Value $Value -Force
            $ToWrite = $Existing
        }

        if ($PSCmdlet.ShouldProcess($Name, 'Set stateful data')) {
            Export-Clixml -Path $Path -InputObject $ToWrite -Depth $Depth -Force
            Write-Verbose -Message "Stateful data [$Name] saved to [$Path]"
        }
    }
}

Export-ModuleMember -Function 'Set-PoshBotStatefulData'
