
InModuleScope PoshBot {
    describe 'Get-PoshBotStatefulData' {
        it 'Returns nothing if no file exists' {
            $pbc = [pscustomobject]@{
                ConfigurationDirectory = (Join-Path $env:BHProjectPath Tests\Data)
            }
            Get-PoshBotStatefulData -Scope Module | Should BeNullorEmpty
            Get-PoshBotStatefulData -Scope Global | Should BeNullorEmpty
        }

        # Set internal variables, create stateful files
        $pbc = [pscustomobject]@{
            ConfigurationDirectory = (Join-Path $env:BHProjectPath Tests\Data)
        }
        $poshbotcontext = [pscustomobject]@{
            Plugin = 'TestPlugin'
        }

        $globalfile = Join-Path $pbc.ConfigurationDirectory "PoshbotGlobal.state"
        $modulefile = Join-Path $pbc.ConfigurationDirectory "$($poshbotcontext.Plugin).state"
        [pscustomobject]@{
            a = 'g'
            b = $true
        } | Export-Clixml -Path $globalfile
        [pscustomobject]@{
            a = 'm'
        } | Export-Clixml -Path $modulefile

        it 'Returns expected data if a file exists' {
            $m = Get-PoshBotStatefulData -Scope Module
            $m.a | Should Be 'm'
            $m.psobject.properties.count | Should Be 1
            
            $g = Get-PoshBotStatefulData -Scope Global
            $g.a | Should Be 'g'
            $g.b | Should Be $True
            @($g.psobject.properties).count | Should Be 2
        }

        it 'Supports ValueOnly' {
            Get-PoshBotStatefulData -Scope Global -Name a -ValueOnly | Should be 'g'
            Get-PoshBotStatefulData -Scope Module -Name a -ValueOnly | Should be 'm'
        }

        Remove-Item $globalfile -Force
        Remove-Item $modulefile -Force
    }
}