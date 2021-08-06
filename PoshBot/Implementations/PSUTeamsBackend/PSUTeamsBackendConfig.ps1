class PSUTeamsBackendConfig  : ConnectionConfig{
    [String] $ClientID
    [String] $TenantID
    hidden [String] $ClientSecret
    [String] $Botname = "PSUBot"
    [string] $ServerVersion
    [string] $ServerRootPath
    [string] $RepoPath

    hidden [string] ServerPath() {
        $PSUPath = (Join-Path $this.ServerRootPath $this.ServerVersion)
        if (Test-Path $PSUPath) {
            return $PSUPath
        } else {
            return "Path not found"
        }
    }
    hidden [string] ServerExecutable() {
        $PSUexe = (Join-Path $this.ServerPath() 'Universal.Server.exe')
        if (Test-Path $PSUexe) {
            return $PSUexe
        } else {
            return "EXE not found"
        }
    }
    [hashtable]appsettings() {
        return @{
            ClientID     = $this.ClientID
            TenantID     = $this.TenantID
            ClientSecret = $this.ClientSecret
        }
    }

    [void]Initialize() {
        Import-Module (Join-Path $this.ServerPath() 'Cmdlets\Universal.psd1')
    }


    [String]ToJson() {
        return (ConvertTo-Json $this.appsettings() -Depth 1)
    }


}