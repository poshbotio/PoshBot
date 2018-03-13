#requires -Modules Configuration

class StorageProvider : BaseLogger {

    [string]$ConfigPath

    StorageProvider([Logger]$Logger) {
        $this.Logger = $Logger
        $this.ConfigPath = $script:defaultPoshBotDir
    }

    StorageProvider([string]$Dir, [Logger]$Logger) {
        $this.Logger = $Logger
        $this.ConfigPath = $Dir
    }

    [hashtable]GetConfig([string]$ConfigName) {
        $path = Join-Path -Path $this.ConfigPath -ChildPath "$($ConfigName).psd1"
        if (Test-Path -Path $path) {
            $this.LogDebug("Loading config [$ConfigName] from [$path]")
            $config = Get-Content -Path $path -Raw | ConvertFrom-Metadata
            return $config
        } else {
            $this.LogInfo([LogSeverity]::Warning, "Configuration file [$path] not found")
            return $null
        }
    }

    [void]SaveConfig([string]$ConfigName, [hashtable]$Config) {
        $path = Join-Path -Path $this.ConfigPath -ChildPath "$ConfigName.psd1"
        $meta = $config | ConvertTo-Metadata
        if (-not (Test-Path -Path $path)) {
            New-Item -Path $Path -ItemType File
        }
        $this.LogDebug("Saving config [$ConfigName] to [$path]")
        $meta | Out-file -FilePath $path -Force -Encoding utf8
    }
}
