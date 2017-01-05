
class RoleUsers {
    [hashtable]$Users = @{}
}

class RoleManager {

    [hashtable]$Roles = @{}

    [hashtable]$RoleUserMapping = @{}

    RoleManager() {
        $this.Initialize()
    }

    [void]Initialize() {
        # TODO
        # Load in state from persistent storage
        $this.LoadState()
    }

    # TODO
    # Save state to storage
    [void]SaveState() {}

    # TODO
    # Load state from storage
    [void]LoadState() {}

    [Role]GetRole([string]$Role) {
        return $this.Roles.$Role
    }

    [void]AddRole([Role]$Role) {
        if (-not $this.Roles.ContainsKey($Role.Name)) {
            $this.Roles.Add($Role.Name, $Role)
            $this.SaveState()
        }
    }

    [void]RemoveRole([Role]$Role) {
        if ($this.Roles.ContainsKey($Role.Name)) {
            $this.Roles.Remove($Role.Name)
            $this.SaveState()
        }
    }

    [void]AddUserToRole([string]$User, [string]$RoleName) {
        if ($role = $this.GetRole($RoleName)) {
            if ($roleUsers = $this.RoleUserMapping.$RoleName) {
                if (-not $roleUsers.Users.ContainsKey($User)) {
                    $roleUsers.Users.Add($user, $null)
                }
            } else {
                $roleUsers = [RoleUsers]::new()
                $roleUsers.Users.Add($User, $null)
                $this.RoleUserMapping.Add($RoleName, $roleUsers)
            }
            $this.SaveState()
        }
    }

    [void]RemoveUserFromRole([string]$User, [string]$RoleName) {
        if ($role = $this.GetRole($RoleName)) {
            if ($roleUsers = $this.RoleUserMapping.$RoleName) {
                if ($roleUsers.Users.ContainsKey($User)) {
                    $roleUsers.Users.Remove($User)
                    $this.SaveState()
                }
            }
        }
    }

    [bool]UserInRole([string]$User, [string]$RoleName) {
        if ($role = $this.GetRole($RoleName)) {
            if ($roleUsers = $this.RoleUserMapping.$RoleName) {
                return $roleUsers.Users.ContainsKey($User)
            } else {
                return $false
            }
        } else {
            return $false
        }
    }

    [string[]]GetUserRoles([string]$User) {
        $userRoles = New-Object System.Collections.ArrayList
        foreach ($role in $this.Roles.Keys) {
            if ($this.UserInRole($User, $role)) {
                $userRoles.Add($role)
            }
        }
        return $userRoles
    }
}
