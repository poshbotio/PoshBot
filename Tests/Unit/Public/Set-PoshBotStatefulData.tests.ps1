
InModuleScope PoshBot {
    describe 'Set-PoshBotStatefulData' {
        # Define internal variables
        $poshbotcontext = [pscustomobject]@{
            Plugin = 'TestPlugin'
            ConfigurationDirectory = (Join-Path $env:BHProjectPath Tests)
        }
        $globalfile = Join-Path $poshbotcontext.ConfigurationDirectory "PoshbotGlobal.state"
        $modulefile = Join-Path $poshbotcontext.ConfigurationDirectory "$($poshbotcontext.Plugin).state"

        it 'Adds data as expected' {
            Set-PoshBotStatefulData -Scope Module -Name a -Value 'm'
            Set-PoshBotStatefulData -Scope Global -Name a -Value 'g'
            $m = Import-Clixml -Path $modulefile
            $m.a | Should Be 'm'
            @($m.psobject.properties).count | Should Be 1
            
            $g = Import-Clixml -Path $globalfile
            $g.a | Should Be 'g'
            @($g.psobject.properties).count | Should Be 1

            Remove-Item $globalfile -Force
            Remove-Item $modulefile -Force
        }

        it 'Appends to existing files' {
            Set-PoshBotStatefulData -Scope Module -Name a -Value 'm'
            Set-PoshBotStatefulData -Scope Global -Name a -Value 'g'
            Set-PoshBotStatefulData -Scope Module -Name b -Value $true
            Set-PoshBotStatefulData -Scope Global -Name b -Value $true
            
            $m = Import-Clixml -Path $modulefile
            $m.a | Should Be 'm'
            $m.b | Should Be $True
            @($m.psobject.properties).count | Should Be 2
            
            $g = Import-Clixml -Path $globalfile
            $g.a | Should Be 'g'
            $g.b | Should Be $True
            @($g.psobject.properties).count | Should Be 2

            Remove-Item $globalfile -Force
            Remove-Item $modulefile -Force
        }

        it 'Intentionally clobbers existing data' {
            Set-PoshBotStatefulData -Scope Global -Name a -Value 'g'
            Set-PoshBotStatefulData -Scope Global -Name a -Value $true
            
            $g = Import-Clixml -Path $globalfile
            $g.a | Should Be $True
            @($g.psobject.properties).count | Should Be 1

            Remove-Item $globalfile -Force
        }

        Remove-Item $globalfile -Force -ErrorAction SilentlyContinue
        Remove-Item $modulefile -Force -ErrorAction SilentlyContinue
    }
}