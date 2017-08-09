
class Role : BaseLogger {
    [string]$Name
    [string]$Description
    [hashtable]$Permissions = @{}

    Role([string]$Name, [Logger]$Logger) {
        $this.Name = $Name
        $this.Logger = $Logger
    }

    Role([string]$Name, [string]$Description, [Logger]$Logger) {
        $this.Name = $Name
        $this.Description = $Description
        $this.Logger = $Logger
    }

    [void]AddPermission([Permission]$Permission) {
        if (-not $this.Permissions.ContainsKey($Permission.ToString())) {
            $this.LogVerbose("Adding permission [$($Permission.Name)] to role [$($this.Name)]")
            $this.Permissions.Add($Permission.ToString(), $Permission)
        }
    }

    [void]RemovePermission([Permission]$Permission) {
        if ($this.Permissions.ContainsKey($Permission.ToString())) {
            $this.LogVerbose("Removing permission [$($Permission.Name)] from role [$($this.Name)]")
            $this.Permissions.Remove($Permission.ToString())
        }
    }

    [hashtable]ToHash() {
        return @{
            Name = $this.Name
            Description = $this.Description
            Permissions = @($this.Permissions.Keys)
        }
    }
}
