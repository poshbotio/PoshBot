
class RoleUsers {
    [hashtable]$Users = @{}
}

class RoleManager {

    [hashtable]$Roles = @{}

    [hashtable]$RoleUserMapping = @{}

    hidden [object]$_Backend

    RoleManager([object]$Backend) {
        $this._Backend = $Backend
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

    [Role]GetRole([string]$RoleName) {
        $r = $this.Roles[$RoleName]
        if ($r) {
            return $r
        } else {
            Write-Error "[RoleManager:GetRole] Role [$RoleName] not found"
            return $null
        }
    }

    [void]AddRole([Role]$Role) {
        if (-not $this.Roles.ContainsKey($Role.Name)) {
            Write-Verbose -Message "[RoleManager:AddRole] Adding role [$($Role.Name)]"
            $this.Roles.Add($Role.Name, $Role)
            $this.SaveState()
        } else {
            Write-Verbose -Message "[RoleManager:AddRole] Role [$($Role.Name)] is already loaded"
        }
    }

    [void]RemoveRole([Role]$Role) {
        if ($this.Roles.ContainsKey($Role.Name)) {
            $this.Roles.Remove($Role.Name)
            $this.SaveState()
        }
    }

    [void]AddUserToRole([string]$UserId, [string]$RoleName) {
        try {
            $userObject = $this._Backend.GetUser($UserId)
            if ($userObject) {
                if ($role = $this.GetRole($RoleName)) {
                    if ($roleUsers = $this.RoleUserMapping[$RoleName]) {
                        if (-not $roleUsers.Users.ContainsKey($UserId)) {
                            $roleUsers.Users.Add($UserId, $userObject)
                        }
                    } else {
                        $roleUsers = [RoleUsers]::new()
                        $roleUsers.Users.Add($UserId, $userObject)
                        $this.RoleUserMapping.Add($RoleName, $roleUsers)
                    }
                    $this.SaveState()
                } else {
                    throw "Unknown role [$RoleName]"
                }
            } else {
                throw "Unable to find user [$UserId]"
            }
        } catch {
            Write-Error $_
        }
    }

    [void]RemoveUserFromRole([string]$UserId, [string]$RoleName) {
        if ($role = $this.GetRole($RoleName)) {
            if ($roleUsers = $this.RoleUserMapping[$RoleName]) {
                if ($roleUsers.Users.ContainsKey($UserId)) {
                    $roleUsers.Users.Remove($UserId)
                    $this.SaveState()
                }
            }
        }
    }

    [bool]UserInRole([string]$UserId, [string]$RoleName) {
        if ($role = $this.GetRole($RoleName)) {
            if ($roleUsers = $this.RoleUserMapping[$RoleName]) {
                return $roleUsers.Users.ContainsKey($UserId)
            } else {
                return $false
            }
        } else {
            return $false
        }
    }

    [string[]]GetUserRoles([string]$UserId) {
        $userRoles = New-Object System.Collections.ArrayList
        foreach ($role in $this.Roles.Keys) {
            if ($this.UserInRole($UserId, $role)) {
                $userRoles.Add($role)
            }
        }
        return $userRoles
    }

    # Resolve a user to their Id
    # This may be passed either a user name or Id
    [string]ResolveUserToId([string]$Username) {
        $id = $this._Backend.UsernameToUserId($Username)
        if ($id) {
            return $id
        } else {
            $name = $this._Backend.UserIdToUsername($Username)
            if ($name) {
                # We already have a valid user ID since we were able to resolve it to a username.
                # Just return what was passed in
                return $Username
            }
        }
        return $null
    }
}
