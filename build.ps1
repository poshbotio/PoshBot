#Requires -Module @{ModuleName = 'BuildHelpers' ; RequiredVersion = '2.0.11'}
#Requires -Module @{ModuleName = 'platyPS' ; RequiredVersion = '0.14.0';}
#Requires -Module @{ModuleName = 'Pester' ; RequiredVersion = '4.8.1';}

[cmdletbinding(DefaultParameterSetName = 'task')]
param(
    # Build task(s) to execute
    [parameter(ParameterSetName = 'task', Position = 0)]
    [ValidateSet('default','Init','Test','Analyze','Pester','Build','Compile','Clean','Publish','Build-Docker','Publish-Docker','RegenerateHelp','UpdateMarkdownHelp','CreateExternalHelp')]
    [string[]]$Task = 'default',

    # Bootstrap dependencies
    [switch]$Bootstrap,

    # List available build tasks
    [parameter(ParameterSetName = 'Help')]
    [switch]$Help
)

$ErrorActionPreference = 'Stop'

# Bootstrap dependencies
if ($Bootstrap.IsPresent) {
    Get-PackageProvider -Name Nuget -ForceBootstrap > $null
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    if (-not (Get-Module -Name PSDepend -ListAvailable)) {
        Install-Module -Name PSDepend -Repository PSGallery -Scope CurrentUser -Force
    }
    Import-Module -Name PSDepend -Verbose:$false
    Invoke-PSDepend -Path './requirements.psd1' -Install -Import -Force -WarningAction SilentlyContinue
}

# Execute psake task(s)
$psakeFile = './psake.ps1'
if ($PSCmdlet.ParameterSetName -eq 'Help') {
    Get-PSakeScriptTasks -buildFile $psakeFile  |
        Format-Table -Property Name, Description, Alias, DependsOn
} else {
    Set-BuildEnvironment -Force

    Invoke-psake -buildFile $psakeFile -taskList $Task -nologo
    exit ( [int]( -not $psake.build_success ) )
}
