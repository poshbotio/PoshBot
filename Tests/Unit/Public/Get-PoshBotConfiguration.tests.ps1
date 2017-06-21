
describe 'Get-PoshBotConfiguration' {

    BeforeAll {
        $PSDefaultParameterValues = @{
            'Get-PoshBotConfiguration:Verbose' = $false
        }
    }

    it 'Gets a configuration from path' {
        $psd1 = Get-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..\Artifacts\Cherry2000.psd1')
        $config = Get-PoshBotConfiguration -Path $psd1
        $config | should not benullorempty
        $config.Name | should be 'Cherry2000'
    }

    it 'Accepts paths from pipeline' {
        $config = (Join-Path -Path $PSScriptRoot -ChildPath '..\..\Artifacts\Cherry2000.psd1') | Get-PoshBotConfiguration
        $config | should not benullorempty
        $config.Name | should be 'Cherry2000'
    }

    it 'Validates path and file type' {
        {Get-PoshBotConfiguration -Path '.\nonexistentfile.asdf'} | should throw
    }

    it 'Accepts LiteralPath' {
        $psd1 = Join-Path -Path $PSScriptRoot -ChildPath '..\..\Artifacts\Cherry2000.psd1'
        $config = Get-PoshBotConfiguration -LiteralPath $psd1
        $config | should not benullorempty
    }
}
