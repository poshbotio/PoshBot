
# A group contains a collection of users and a collection of roles
# those users will be a member of
class Group {
    [string]$Name
    [string]$Description
    [hashtable]$Users = @{}
    [hashtable]$Roles = @{}

    Group([string]$Name) {
        $this.Name = $Name
    }

    Group([string]$Name, [string]$Description) {
        $this.Name = $Name
        $this.Description = $Description
    }

    [void]AddRole([Role]$Role) {
        if (-not $this.Roles.ContainsKey($Role.Name)) {
            $this.Roles.Add($Role.Name, $Role)
        }
    }

    [void]RemoveRole([Role]$Role) {
        if ($this.Roles.ContainsKey($Role.Name)) {
            $this.Roles.Remove($Role.Name)
        }
    }

    [void]AddUser([string]$Username) {
        if (-not $this.Users.ContainsKey($Username)) {
            Write-Verbose "[Group: AddUser] Adding user [$Username] to [$($this.Name)]"
            $this.Users.Add($Username, $null)
        } else {
            Write-Verbose "[Group: AddUser] User [$Username] is already in [$($this.Name)]"
        }
    }

    [void]RemoveUser([string]$Username) {
        if ($this.Users.ContainsKey($Username)) {
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
