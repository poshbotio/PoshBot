
class Role {
    [string]$Name
    [string]$Description
    [hashtable]$Permissions = @{}

    Role([string]$Name) {
        $this.Name = $Name
    }

    Role([string]$Name, [string]$Description) {
        $this.Name = $Name
        $this.Description = $Description
    }

    [void]AddPermission([Permission]$Permission) {
        if (-not $this.Permissions.ContainsKey($Permission.ToString())) {
            $this.Permissions.Add($Permission.ToString(), $Permission)
        }
    }

    [void]RemovePermission([Permission]$Permission) {
        if ($this.Permissions.ContainsKey($Permission.ToString())) {
            $this.Permissions.Remove($Permission.ToString())
        }
    }
}
