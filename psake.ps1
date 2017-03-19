properties {
    $projectRoot = $ENV:BHProjectPath
    if(-not $projectRoot) {
        $projectRoot = $PSScriptRoot
    }

    $sut = "$projectRoot\$env:BHProjectName"
    $tests = "$projectRoot\Tests"

    $psVersion = $PSVersionTable.PSVersion.Major
}

task default -depends Test

task Init {
    "`nSTATUS: Testing with PowerShell $psVersion"
    "Build System Details:"
    Get-Item ENV:BH*

    $modules = 'Pester', 'platyPS', 'PSScriptAnalyzer'
    Install-Module $modules -Repository PSGallery -Confirm:$false
    Import-Module $modules -Verbose:$false -Force
} -description 'Initialize build environment'

task Test -Depends Init, Analyze, Pester -description 'Run test suite'

task Analyze -Depends Init {
    $saResults = Invoke-ScriptAnalyzer -Path $sut -Severity Error -Recurse -Verbose:$false
    if ($saResults) {
        $saResults | Format-Table
        Write-Error -Message 'One or more Script Analyzer errors/warnings where found. Build cannot continue!'
    }
} -description 'Run PSScriptAnalyzer'

task Pester -Depends Init {
    if(-not $ENV:BHProjectPath) {
        Set-BuildEnvironment -Path $PSScriptRoot\..
    }
    Remove-Module $ENV:BHProjectName -ErrorAction SilentlyContinue
    Import-Module (Join-Path $ENV:BHProjectPath $ENV:BHProjectName) -Force

    Invoke-Pester -Path $tests -PassThru -EnableExit
} -description 'Run Pester tests'

task CreateMarkdownHelp -Depends Init {
    Import-Module -Name $sut -Force -Verbose:$false
    New-MarkdownHelp -Module $env:BHProjectName -OutputFolder "$projectRoot\docs\reference\functions" -WithModulePage -Force
} -description 'Create initial markdown help files'

task UpdateMarkdownHelp -Depends Init {
    Import-Module -Name $sut -Force -Verbose:$false
    Update-MarkdownHelpModule -Path "$projectRoot\docs\reference\functions"
} -description 'Update markdown help files'

task CreateExternalHelp -Depends Init {
    New-ExternalHelp "$projectRoot\docs\reference\functions" -OutputPath "$sut\en-US"

} -description 'Create module help from markdown files'

Task RegenerateHelp -Depends Init, UpdateMarkdownHelp, CreateExternalHelp
