
Describe 'New-PoshBotInstance' {

    BeforeAll {
        $VerbosePreference = 'SilentlyContinue'
        $PSDefaultParameterValues = @{
            'New-PoshBotInstance:Verbose' = $false
        }
        $script:backend = New-PoshBotSlackBackend -Configuration @{Token = (New-Guid).ToString(); Name = 'Test-Backend'}
    }

    Context 'Path' {
        it 'Creates a bot instance from a configuration path' {
            $psd1 = Get-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..\Artifacts\Cherry2000.psd1')
            $bot = New-PoshBotInstance -Path $psd1 -Backend $script:backend
            $bot | should not benullorempty
            $bot.PSObject.TypeNames[0] | should be 'Bot'
        }

        it 'Accepts paths from pipeline' {
            $bot = (Join-Path -Path $PSScriptRoot -ChildPath '..\..\Artifacts\Cherry2000.psd1') | New-PoshBotInstance -Backend $script:backend
            $bot | should not benullorempty
            $bot.PSObject.TypeNames[0] | should be 'Bot'
        }

        it 'Validates path and file type' {
            {New-PoshBotInstance -Path '.\nonexistentfile.asdf' -Backend $script:backend} | should throw
        }
    }

    Context 'LiteralPath' {
        it 'Accepts LiteralPath' {
            $psd1 = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Artifacts\Cherry2000.psd1'
            $config = New-PoshBotInstance -LiteralPath $psd1 -Backend $script:backend
            $config | should not benullorempty
        }
    }

    Context 'Configuration' {
        it 'Accepts configuration object' {
            $psd1 = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Artifacts\Cherry2000.psd1'
            $config = $psd1 | Get-PoshBotConfiguration
            $bot = New-PoshBotInstance -Configuration $config -Backend $script:backend
        }

        it 'Accepts configuration object from pipeline' {
            $psd1 = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Artifacts\Cherry2000.psd1'
            $config = $psd1 | Get-PoshBotConfiguration
            $bot = $config | New-PoshBotInstance -Backend $script:backend
        }
    }
}
