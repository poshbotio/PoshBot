
[cmdletbinding(DefaultParameterSetName = 'task')]
param(
    [parameter(ParameterSetName = 'task')]
    [string[]]$Task = 'default',

    [parameter(ParameterSetName = 'help')]
    [switch]$Help
)

function Resolve-Module {
    [Cmdletbinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [string[]]$Name
    )

    Process {
        foreach ($ModuleName in $Name) {
            $Module = Get-Module -Name $ModuleName -ListAvailable -Verbose:$false
            Write-Verbose -Message "Resolving Module [$($ModuleName)]"

            if ($Module) {
                $Version = $Module | Measure-Object -Property Version -Maximum | Select-Object -ExpandProperty Maximum
                $GalleryVersion = Find-Module -Name $ModuleName -Repository PSGallery -Verbose:$false |
                    Measure-Object -Property Version -Maximum |
                    Select-Object -ExpandProperty Maximum

                if ($Version -lt $GalleryVersion) {
                    Write-Verbose -Message "$($ModuleName) Installed Version [$($Version.tostring())] is outdated. Installing Gallery Version [$($GalleryVersion.tostring())]"

                    Install-Module -Name $ModuleName -Verbose:$false -Force
                    Import-Module -Name $ModuleName -Verbose:$false -Force -RequiredVersion $GalleryVersion
                }
                else {
                    Write-Verbose -Message "Module Installed, Importing [$($ModuleName)]"
                    Import-Module -Name $ModuleName -Verbose:$false -Force -RequiredVersion $Version
                }
            }
            else {
                Write-Verbose -Message "[$($ModuleName)] Missing, installing Module"
                Install-Module -Name $ModuleName -Verbose:$false -Force
                Import-Module -Name $ModuleName -Verbose:$false -Force -RequiredVersion $Version
            }
        }
    }
}

Get-PackageProvider -Name Nuget -ForceBootstrap | Out-Null
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

'BuildHelpers', 'psake' | Resolve-Module

if ($PSBoundParameters.ContainsKey('help')) {
    Get-PSakeScriptTasks -buildFile "$PSScriptRoot\psake.ps1" |
        Format-Table -Property Name, Description, Alias, DependsOn
} else {
    Set-BuildEnvironment

    Invoke-psake -buildFile "$PSScriptRoot\psake.ps1" -taskList $Task -nologo -Verbose:$VerbosePreference
    exit ( [int]( -not $psake.build_success ) )
}
