
# A group contains a collection of users and a collection of roles
# those users will be a member of
class Group : BaseLogger {
    [string]$Name
    [string]$Description
    [hashtable]$Users = @{}
    [hashtable]$Roles = @{}

    Group([string]$Name, [Logger]$Logger) {
        $this.Name = $Name
        $this.Logger = $Logger
    }

    Group([string]$Name, [string]$Description, [Logger]$Logger) {
        $this.Name = $Name
        $this.Description = $Description
        $this.Logger = $Logger
    }

    [void]AddRole([Role]$Role) {
        if (-not $this.Roles.ContainsKey($Role.Name)) {
            $this.LogVerbose("Adding role [$($Role.Name)] to group [$($this.Name)]")
            $this.Roles.Add($Role.Name, $Role)
        } else {
            $this.LogVerbose([LogSeverity]::Warning, "Role [$($Role.Name)] is already in group [$($this.Name)]")
        }
    }

    [void]RemoveRole([Role]$Role) {
        if ($this.Roles.ContainsKey($Role.Name)) {
            $this.LogVerbose("Removing role [$($Role.Name)] from group [$($this.Name)]")
            $this.Roles.Remove($Role.Name)
        }
    }

    [void]AddUser([string]$Username) {
        if (-not $this.Users.ContainsKey($Username)) {
            $this.LogVerbose("Adding user [$Username)] to group [$($this.Name)]")
            $this.Users.Add($Username, $null)
        } else {
            $this.LogVerbose([LogSeverity]::Warning, "User [$Username)] is already in group [$($this.Name)]")
        }
    }

    [void]RemoveUser([string]$Username) {
        if ($this.Users.ContainsKey($Username)) {
            $this.LogVerbose("Removing user [$Username)] from group [$($this.Name)]")
            $this.Users.Remove($Username)
        }
    }

    [hashtable]ToHash() {
        return @{
            Name = $this.Name
            Description = $this.Description
            Users = $this.Users.Keys
            Roles = $this.Roles.Keys
        }
    }
}
