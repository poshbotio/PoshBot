properties {
    $projectRoot = $ENV:BHProjectPath
    if(-not $projectRoot) {
        $projectRoot = $PSScriptRoot
    }

    $sut = "$projectRoot\$env:BHProjectName"
    $tests = "$projectRoot\Tests"
    $outputDir = Join-Path -Path $projectRoot -ChildPath 'out'
    $outputModDir = Join-Path -Path $outputDir -ChildPath $env:BHProjectName
    $manifest = Import-PowerShellDataFile -Path $env:BHPSModuleManifest
    $outputModVerDir = Join-Path -Path $outputModDir -ChildPath $manifest.ModuleVersion
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

task Analyze -Depends Init, Build {
    $analysis = Invoke-ScriptAnalyzer -Path $outputModVerDir -Verbose:$false
    $errors = $analysis | Where-Object {$_.Severity -eq 'Error'}
    $warnings = $analysis | Where-Object {$_.Severity -eq 'Warning'}
    if (@($errors).Count -gt 0) {
        Write-Error -Message 'One or more Script Analyzer errors were found. Build cannot continue!'
        $errors | Format-Table
    }

    if (@($warnings).Count -gt 0) {
        Write-Warning -Message 'One or more Script Analyzer warnings were found. These should be corrected.'
        $warnings | Format-Table
    }
} -description 'Run PSScriptAnalyzer'

task Pester -Depends Init, Build {
    if(-not $ENV:BHProjectPath) {
        Set-BuildEnvironment -Path $PSScriptRoot\..
    }
    Remove-Module $ENV:BHProjectName -ErrorAction SilentlyContinue -Verbose:$false
    Import-Module -Name $outputModDir -Force -Verbose:$false
    $testResultsXml = Join-Path -Path $outputDir -ChildPath 'testResults.xml'
    $testResults = Invoke-Pester -Path $tests -PassThru -OutputFile $testResultsXml -OutputFormat NUnitXml
    if ($testResults.FailedCount -gt 0) {
        $testResults | Format-List
        Write-Error -Message 'One or more Pester tests failed. Build cannot continue!'
    }
} -description 'Run Pester tests'

task CreateMarkdownHelp -Depends Init {
    Import-Module -Name $outputModDir -Verbose:$false
    New-MarkdownHelp -Module $env:BHProjectName -OutputFolder "$projectRoot\docs\reference\functions" -WithModulePage -Force
} -description 'Create initial markdown help files'

task UpdateMarkdownHelp -Depends Init {
    #Import-Module -Name $sut -Force -Verbose:$false
    Import-Module -Name $outputModDir -Verbose:$false
    $mdHelpPath = Join-Path -Path $projectRoot -ChildPath 'docs/reference/functions'
    $mdFiles = Update-MarkdownHelpModule -Path $mdHelpPath -Verbose:$false
    "    Markdown help updated at [$mdHelpPath]"
} -description 'Update markdown help files'

task CreateExternalHelp -Depends Init {
    New-ExternalHelp "$projectRoot\docs\reference\functions" -OutputPath "$sut\en-US"

} -description 'Create module help from markdown files'

Task RegenerateHelp -Depends Init, UpdateMarkdownHelp, CreateExternalHelp

Task Publish -Depends Init {
    "    Publishing version [$($manifest.ModuleVersion)] to PSGallery..."
    Publish-Module -Path $outputModVerDir -NuGetApiKey $env:PSGalleryApiKey -Repository PSGallery
}

task Clean -depends Init {
    Remove-Module -Name $env:BHProjectName -Force -ErrorAction SilentlyContinue

    if (Test-Path -Path $outputDir) {
        Get-ChildItem -Path $outputDir -Recurse | Remove-Item -Force -Recurse
    } else {
        New-Item -Path $outputDir -ItemType Directory > $null
    }
    "    Cleaned previous output directory [$outputDir]"
} -description 'Cleans module output directory'

task Compile -depends Clean {

    # Create module output directory
    $modDir = New-Item -Path $outputModDir -ItemType Directory
    New-Item -Path $outputModVerDir -ItemType Directory > $null

    # Append items to psm1
    Write-Verbose -Message 'Creating psm1...'
    $psm1 = New-Item -Path (Join-Path -Path $outputModVerDir -ChildPath "$($ENV:BHProjectName).psm1") -ItemType File

    # This is dumb but oh well :)
    # We need to write out the classes in a particular order
    $classDir = (Join-Path -Path $sut -ChildPath 'Classes')
    @(
        'Enums'
        'Logger'
        'ExceptionFormatter'
        'BotCommand'
        'Event'
        'Person'
        'Room'
        'Message'
        'Response'
        'Card'
        'CommandResult'
        'CommandParser'
        'Permission'
        'AccessFilter'
        'Role'
        'Group'
        'Trigger'
        'StorageProvider'
        'RoleManager'
        'Command'
        'CommandHistory'
        'Plugin'
        'PluginCommand'
        'CommandExecutor'
        'ConfigProvidedParameter'
        'PluginManager'
        'ConnectionConfig'
        'Connection'
        'Backend'
        'BotConfiguration'
        'Bot'
    ) | ForEach-Object {
        Get-Content -Path (Join-Path -Path $classDir -ChildPath "$($_).ps1") | Add-Content -Path $psm1 -Encoding UTF8
    }
    # Get-ChildItem -Path (Join-Path -Path $sut -ChildPath 'Classes') -Recurse |
    #     Get-Content -Raw | Add-Content -Path $psm1 -Encoding UTF8
    Get-ChildItem -Path (Join-Path -Path $sut -ChildPath 'Private') -Recurse |
        Get-Content -Raw | Add-Content -Path $psm1 -Encoding UTF8
    Get-ChildItem -Path (Join-Path -Path $sut -ChildPath 'Public') -Recurse |
        Get-Content -Raw | Add-Content -Path $psm1 -Encoding UTF8
    Get-ChildItem -Path (Join-Path -Path $sut -ChildPath 'Implementations') -File -Recurse |
        Get-Content -Raw | Add-Content -Path $psm1 -Encoding UTF8

    # Copy over other items
    Copy-Item -Path $env:BHPSModuleManifest -Destination $outputModVerDir
    #Copy-Item -Path (Join-Path -Path $sut -ChildPath 'Implementations') -Destination $outputModVerDir -Recurse
    Copy-Item -Path (Join-Path -Path $classDir -ChildPath 'PoshBotAttribute.ps1') -Destination $outputModVerDir
    Copy-Item -Path (Join-Path -Path $sut -ChildPath 'Plugins') -Destination $outputModVerDir -Recurse
    Copy-Item -Path (Join-Path -Path $sut -ChildPath 'Task') -Destination $outputModVerDir -Recurse

    "    Created compiled module at [$modDir]"
} -description 'Compiles module from source'

task build -depends Compile, UpdateMarkdownHelp {
    # External help
    $helpXml = New-ExternalHelp "$projectRoot\docs\reference\functions" -OutputPath (Join-Path -Path $outputModVerDir -ChildPath 'en-US')
    "    XML help created at [$helpXml]"
}
