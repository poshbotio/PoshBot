#requires -Modules Configuration

class StorageProvider {

    [string]$ConfigPath

    StorageProvider() {
        $this.ConfigPath = (Join-Path -Path $env:USERPROFILE -ChildPath '.poshbot')
    }

    StorageProvider([string]$Dir) {
        $this.ConfigPath = $Dir
    }

    [hashtable]GetConfig([string]$ConfigName) {
        $path = Join-Path -Path $this.ConfigPath -ChildPath "$ConfigName.psd1"
        if (Test-Path -Path $path) {
            $config = Get-Content -Path $path -Raw | ConvertFrom-Metadata
            return $config
        } else {
            Write-Error "Configuration [$path] not found"
            return $null
        }
    }

    [void]SaveConfig([string]$ConfigName, [hashtable]$Config) {
        $path = Join-Path -Path $this.ConfigPath -ChildPath "$ConfigName.psd1"
        $meta = $config | ConvertTo-Metadata
        if (-not (Test-Path -Path $path)) {
            New-Item -Path $Path -ItemType File
        }
        $meta | Out-file -FilePath $path -Force -Encoding utf8
    }
}
