
InModuleScope PoshBot {
    describe 'Set-PoshBotStatefulData' {
        BeforeAll {
            $PSDefaultParameterValues = @{
                'Set-PoshBotStatefulData:Verbose' = $false
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

        # Define internal variables
        $poshbotcontext = [pscustomobject]@{
            Plugin = 'TestPlugin'
            ConfigurationDirectory = (Join-Path $env:BHProjectPath Tests)
        }
        $globalfile = Join-Path $global:PoshBotContext.ConfigurationDirectory 'PoshbotGlobal.state'
        $modulefile = Join-Path $global:PoshBotContext.ConfigurationDirectory "$($poshbotcontext.Plugin).state"

        AfterEach {
            Remove-Item $globalfile -Force -ErrorAction SilentlyContinue
            Remove-Item $modulefile -Force -ErrorAction SilentlyContinue
        }

        it 'Adds data as expected' {
            Set-PoshBotStatefulData -Scope Module -Name a -Value 'm'
            Set-PoshBotStatefulData -Scope Global -Name a -Value 'g'
            $m = Import-Clixml -Path $modulefile
            $m.a | Should Be 'm'
            @($m.psobject.properties).count | Should Be 1

            $g = Import-Clixml -Path $globalfile
            $g.a | Should Be 'g'
            @($g.psobject.properties).count | Should Be 1
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
        }

        it 'Handles custom objects' {
            Set-PoshBotStatefulData -Scope Module -Name a -Value ([pscustomobject]@{prop1 = 'asdf'; prop2 = '42'})
            $m = Import-Clixml -Path $modulefile
            $m.a -is [pscustomObject] | should be $true
            $m.a.prop1 | should be 'asdf'
            $m.a.prop2 | should be 42
        }

        it 'Handles arrays of objects' {
            $arr = @()
            $arr += [pscustomobject]@{prop1 = 'asdf'; prop2 = '42'}
            $arr += [pscustomobject]@{prop1 = 'qwerty'; prop2 = '37'}
            Set-PoshBotStatefulData -Scope Module -Name a -Value $arr
            $m = Import-Clixml -Path $modulefile
            $m.a.Count | Should Be 2
        }

        it 'Intentionally clobbers existing data' {
            Set-PoshBotStatefulData -Scope Global -Name a -Value 'g'
            Set-PoshBotStatefulData -Scope Global -Name a -Value $true

            $g = Import-Clixml -Path $globalfile
            $g.a | Should Be $True
            @($g.psobject.properties).count | Should Be 1
        }
    }
}
