properties {
    $projectRoot = $ENV:BHProjectPath
    if(-not $projectRoot) {
        $projectRoot = $PSScriptRoot
    }

    $sut = $env:BHModulePath
    $tests = "$projectRoot\Tests"
    $outputDir = Join-Path -Path $projectRoot -ChildPath 'out'
    $outputModDir = Join-Path -Path $outputDir -ChildPath $env:BHProjectName
    $manifest = Import-PowerShellDataFile -Path $env:BHPSModuleManifest
    $outputModVerDir = Join-Path -Path $outputModDir -ChildPath $manifest.ModuleVersion
    $psVersion = $PSVersionTable.PSVersion.Major
    $pathSeperator = [IO.Path]::PathSeparator

    $dotnetFramework = 'netstandard2.0'
    $release = 'release'

    $dockerImages = @(
        'ubuntu16.04'
        #'nano1803'
    )
}

task default -depends Test

task Init {
    "`nSTATUS: Testing with PowerShell $psVersion"
    "Build System Details:"
    Get-Item ENV:BH*
    "`n"

    'Configuration', 'Pester', 'platyPS', 'PSScriptAnalyzer', 'PSSlack' | Foreach-Object {
        if (-not (Get-Module -Name $_ -ListAvailable -Verbose:$false -ErrorAction SilentlyContinue)) {
            Install-Module -Name $_ -Repository PSGallery -Scope CurrentUser -AllowClobber -Confirm:$false -ErrorAction Stop
        }
        Import-Module -Name $_ -Verbose:$false -Force -ErrorAction Stop
    }
} -description 'Initialize build environment'

task Test -Depends Init, Analyze, Pester -description 'Run test suite'

task Analyze -Depends Build {
    $analysis = Invoke-ScriptAnalyzer -Path $outputModVerDir -Verbose:$false
    $errors = $analysis | Where-Object {$_.Severity -eq 'Error'}
    $warnings = $analysis | Where-Object {$_.Severity -eq 'Warning'}

    if (($errors.Count -eq 0) -and ($warnings.Count -eq 0)) {
        '    PSScriptAnalyzer passed without errors or warnings'
    }

    if (@($errors).Count -gt 0) {
        Write-Error -Message 'One or more Script Analyzer errors were found. Build cannot continue!'
        $errors | Format-Table
    }

    if (@($warnings).Count -gt 0) {
        Write-Warning -Message 'One or more Script Analyzer warnings were found. These should be corrected.'
        $warnings | Format-Table
    }
} -description 'Run PSScriptAnalyzer'

task Pester -Depends Build {
    Push-Location
    Set-Location -PassThru $outputModDir
    if(-not $ENV:BHProjectPath) {
        Set-BuildEnvironment -Path $PSScriptRoot\..
    }

    $origModulePath = $env:PSModulePath
    if ( $env:PSModulePath.split($pathSeperator) -notcontains $outputDir ) {
        $env:PSModulePath = ($outputDir + $pathSeperator + $origModulePath)
    }

    Remove-Module $ENV:BHProjectName -ErrorAction SilentlyContinue -Verbose:$false
    Import-Module -Name $outputModDir -Force -Verbose:$false
    $testResultsXml = Join-Path -Path $outputDir -ChildPath 'testResults.xml'
    $testResults = Invoke-Pester -Path $tests -PassThru -OutputFile $testResultsXml -OutputFormat NUnitXml

    # Upload test artifacts to AppVeyor
    if ($env:APPVEYOR_JOB_ID) {
        $wc = New-Object 'System.Net.WebClient'
        $wc.UploadFile("https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)", $testResultsXml)
    }

    if ($testResults.FailedCount -gt 0) {
        $testResults | Format-List
        Write-Error -Message 'One or more Pester tests failed. Build cannot continue!'
    }
    Pop-Location
    $env:PSModulePath = $origModulePath
} -description 'Run Pester tests'

task CreateMarkdownHelp -Depends Compile {
    # PoshBot functions
    Import-Module -Name $outputModDir -Verbose:$false -Global
    $mdHelpPath = Join-Path -Path $projectRoot -ChildPath 'docs/reference/functions'
    $mdFiles = New-MarkdownHelp -Module $env:BHProjectName -OutputFolder $mdHelpPath -WithModulePage -Force
    "    PoshBot markdown help created at [$mdHelpPath]"

    # Builtin commands
    Import-Module -Name $outputModVerDir/Plugins/Builtin -Verbose:$false -Global
    $mdHelpPath = Join-Path -Path $projectRoot -ChildPath 'docs/reference/commands'
    $mdFiles = New-MarkdownHelp -Module 'Builtin' -OutputFolder $mdHelpPath -WithModulePage -Force
    "    Builtin plugin markdown help created at [$mdHelpPath]"

    @('Builtin', $env:BHProjectName).ForEach({
        Remove-Module -Name $_ -Verbose:$false
    })
} -description 'Create initial markdown help files'

task UpdateMarkdownHelp -Depends Compile {
    #Import-Module -Name $sut -Force -Verbose:$false
    Import-Module -Name $outputModDir -Verbose:$false
    $mdHelpPath = Join-Path -Path $projectRoot -ChildPath 'docs/reference/functions'
    $mdFiles = Update-MarkdownHelpModule -Path $mdHelpPath -Verbose:$false
    "    Markdown help updated at [$mdHelpPath]"
} -description 'Update markdown help files'

task CreateExternalHelp -Depends CreateMarkdownHelp {
    New-ExternalHelp "$projectRoot\docs\reference\functions" -OutputPath "$outputModVerDir\en-US" -Force > $null
} -description 'Create module help from markdown files'

Task RegenerateHelp -Depends UpdateMarkdownHelp, CreateExternalHelp

Task Publish -Depends Test {
    "    Publishing version [$($manifest.ModuleVersion)] to PSGallery..."
    Publish-Module -Path $outputModVerDir -NuGetApiKey $env:PSGALLERY_API_KEY -Repository PSGallery
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
    $psm1 = Copy-Item -Path (Join-Path -Path $sut -ChildPath 'PoshBot.psm1') -Destination (Join-Path -Path $outputModVerDir -ChildPath "$($ENV:BHProjectName).psm1") -PassThru

    # This is dumb but oh well :)
    # We need to write out the classes in a particular order
    $classDir = (Join-Path -Path $sut -ChildPath 'Classes')
    @(
        'Enums'
        'LogMessage'
        'Logger'
        'BaseLogger'
        'ExceptionFormatter'
        'Event'
        'Person'
        'Room'
        'Response'
        'Message'
        'Stream'
        'CommandResult'
        'ParsedCommand'
        'CommandParser'
        'Permission'
        'CommandAuthorizationResult'
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
        'Approver'
        'CommandExecutionContext'
        'MiddlewareHook'
        'MiddlewareConfiguration'
        'CommandExecutor'
        'ScheduledMessage'
        'Scheduler'
        'ConfigProvidedParameter'
        'PluginManager'
        'ConnectionConfig'
        'Connection'
        'Backend'
        'ApprovalCommandConfiguration'
        'ApprovalConfiguration'
        'ChannelRule'
        'BotConfiguration'
        'Bot'
    ) | ForEach-Object {
        Get-Content -Path (Join-Path -Path $classDir -ChildPath "$($_).ps1") | Add-Content -Path $psm1 -Encoding UTF8
    }
    Get-ChildItem -Path (Join-Path -Path $sut -ChildPath 'Private') -Recurse |
        Get-Content -Raw | Add-Content -Path $psm1 -Encoding UTF8
    Get-ChildItem -Path (Join-Path -Path $sut -ChildPath 'Public') -Recurse |
        Get-Content -Raw | Add-Content -Path $psm1 -Encoding UTF8
    Get-ChildItem -Path (Join-Path -Path $sut -ChildPath 'Implementations') -File -Recurse -Filter '*.ps1' -Exclude '*ServiceBusReceiver*.ps1' |
        Get-Content -Raw | Add-Content -Path $psm1 -Encoding UTF8

    # Copy over "lib" files.
    # These are the Service Bus DLLs and scripts
    New-Item -Path $outputModVerDir/lib -ItemType Directory > $null
    Copy-Item -Path "$sut/lib/*" -Destination $outputModVerDir/lib -Recurse
    Copy-Item -Path "$sut/Implementations/Teams/*netstandard*.ps1" -Destination $outputModVerDir/lib/linux
    Copy-Item -Path "$sut/Implementations/Teams/*net45*.ps1"       -Destination $outputModVerDir/lib/windows

    # Copy over other items
    Copy-Item -Path $env:BHPSModuleManifest -Destination $outputModVerDir
    Copy-Item -Path (Join-Path -Path $classDir -ChildPath 'PoshBotAttribute.ps1') -Destination $outputModVerDir
    Copy-Item -Path (Join-Path -Path $sut -ChildPath 'Plugins') -Destination $outputModVerDir -Recurse
    Copy-Item -Path (Join-Path -Path $sut -ChildPath 'Task') -Destination $outputModVerDir -Recurse

    # Fix case of PSM1 and PSD1
    Rename-Item -Path $outputModVerDir/poshbot.psd1 -NewName PoshBot.psd1
    Rename-Item -Path $outputModVerDir/poshbot.psm1 -NewName PoshBot.psm1

    "    Created compiled module at [$modDir]"
} -description 'Compiles module from source'

task Build -depends Compile, CreateMarkdownHelp, CreateExternalHelp {
    # External help
    $helpXml = New-ExternalHelp "$projectRoot\docs\reference\functions" -OutputPath (Join-Path -Path $outputModVerDir -ChildPath 'en-US') -Force
    "    Module XML help created at [$helpXml]"
}

task Build-Docker {
    $version = $manifest.ModuleVersion.ToString()
    Push-Location
    Set-Location -Path $projectRoot
    $dockerImages | Foreach-Object {
        $dockerFilePath = Join-Path $projectRoot -ChildPath 'docker' -AdditionalChildPath @($_, 'Dockerfile')
        $tag = "$_-$version"
        $imageName = "poshbotio/poshbot`:$tag"
        "Building docker image: $imageName"
        exec {
            & docker build -t $imageName --label version=$version -f $dockerFilePath .
        }
    }
    Pop-Location
} -description 'Create Docker container'

task Publish-Docker -depends Build-Docker {
    $version = $manifest.ModuleVersion.ToString()
    exec {
        docker login
    }

    $dockerImages | Foreach-Object {
        $tag = "$_-$version"
        $imageName = "poshbotio/poshbot`:$tag"
        "Publishing docker image: $imageName"
        exec {
            docker push $imageName
        }
    }

    # docker push poshbotio/poshbot-nano-slack:latest
    # docker push poshbotio/poshbot-nano-slack:$version
}
