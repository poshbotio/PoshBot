
InModuleScope PoshBot {
    describe 'Get-PoshBotStatefulData' {
        BeforeAll {
            $PSDefaultParameterValues = @{
                'Get-PoshBotStatefulData:Verbose' = $false
            }

            # Define internal variables
            $global:PoshBotContext = [pscustomobject]@{
                Plugin                 = 'TestPlugin'
                ConfigurationDirectory = (Join-Path $env:BHProjectPath Tests)
            }
        }

        AfterAll {
            Remove-Variable -Name PoshBotContext -Scope Global -Force
        }

        it 'Returns nothing if no file exists' {
            Get-PoshBotStatefulData -Scope Module | Should BeNullorEmpty
            Get-PoshBotStatefulData -Scope Global | Should BeNullorEmpty
        }

        # Create stateful files
        $globalfile = Join-Path $global:PoshBotContext.ConfigurationDirectory 'PoshbotGlobal.state'
        $modulefile = Join-Path $global:PoshBotContext.ConfigurationDirectory "$($poshbotcontext.Plugin).state"
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
