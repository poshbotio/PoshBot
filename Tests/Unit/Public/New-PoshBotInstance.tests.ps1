
Describe 'New-PoshBotInstance' {

    BeforeAll {
        $VerbosePreference = 'SilentlyContinue'
        $PSDefaultParameterValues = @{
            'New-PoshBotInstance:Verbose' = $false
        }
        $script:psd1    = Get-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..\Artifacts\Cherry2000.psd1')
        $script:backend = New-PoshBotSlackBackend -Configuration @{Token = (New-Guid).ToString(); Name = 'Test-Backend'}
        $script:bot     = New-PoshBotInstance -Path $psd1 -Backend $script:backend -WarningAction Ignore
    }

    AfterAll {
        $script:bot.Dispose()
    }

    Context 'Path' {
        it 'Creates a bot instance from a configuration path' {
            $script:bot | Should -Not -BeNullOrEmpty
            $script:bot.PSObject.TypeNames[0] | Should -Be 'Bot'
        }

        it 'Accepts paths from pipeline' {
            $script:bot = $script:psd1 | New-PoshBotInstance -Backend $script:backend -WarningAction Ignore
            $script:bot | Should -Not -BeNullOrEmpty
            $script:bot.PSObject.TypeNames[0] | Should -Be 'Bot'
        }

        it 'Validates path and file type' {
            {New-PoshBotInstance -Path '.\nonexistentfile.asdf' -Backend $script:backend} | Should -Throw
        }
    }

    Context 'LiteralPath' {
        it 'Accepts LiteralPath' {
            $config = New-PoshBotInstance -LiteralPath $script:psd1 -Backend $script:backend -WarningAction Ignore
            $config | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Configuration' {
        it 'Accepts configuration object' {
            $config = $script:psd1 | Get-PoshBotConfiguration
            {$script:bot = New-PoshBotInstance -Configuration $config -Backend $script:backend -WarningAction Ignore} | Should -Not -Throw
        }

        it 'Accepts configuration object from pipeline' {
            $config = $script:psd1 | Get-PoshBotConfiguration
            {$script:bot = $config | New-PoshBotInstance -Backend $script:backend -WarningAction Ignore} | Should -Not -Throw
        }
    }
}
