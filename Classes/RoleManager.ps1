
class RoleManager {

    [hashtable]$Roles = @{}
    [hashtable]$RoleUserMapping = @{}
    hidden [object]$_Backend
    hidden [StorageProvider]$_Storage
    hidden [Logger]$_Logger

    RoleManager([object]$Backend, [StorageProvider]$Storage, [Logger]$Logger) {
        $this._Backend = $Backend
        $this._Storage = $Storage
        $this._Logger = $Logger
        $this.Initialize()
    }

    [void]Initialize() {
        # Load in state from persistent storage
        $this._Logger.Log([LogMessage]::new('[RoleManager:Initialize] Initializing'), [LogType]::System)

        $adminrole = [Role]::New('Admin', 'Bot administrators')
        $this.AddRole($adminRole)

        $this.LoadState()
    }

    # TODO
    # Save state to storage
    [void]SaveState() {
        $this._Logger.Log([LogMessage]::new("[RoleManager:SaveState] Saving role state to storage"), [LogType]::System)

        # Don't attempt to store role instances to storage, just the representation of them.
        # When loading from storage, the role objects will be recreated from this data
        $rolesToSave = @{}
        $this.Roles.GetEnumerator() | ForEach-Object {
            $rolesToSave.Add($_.Name, $_.Value.Description)
        }
        $this._Storage.SaveConfig('roles', $rolesToSave)

        $this._Storage.SaveConfig('roleusermapping', $this.RoleUserMapping)
    }

    # TODO
    # Load state from storage
    [void]LoadState() {
        $this._Logger.Log([LogMessage]::new("[RoleManager:LoadState] Loading role state from storage"), [LogType]::System)
        $roleConfig = $this._Storage.GetConfig('roles')
        if ($roleConfig) {
            $roleConfig.GetEnumerator() | ForEach-Object {
                $r = [Role]::new($_.Name)
                $r.Description = $_.Value
                if (-not $this.Roles.ContainsKey($r.Name)) {
                    $this.Roles.Add($r.Name, $r)
                }
            }
        }

        $mappingConfig = $this._Storage.GetConfig('roleusermapping')
        if ($mappingConfig) {
            $this._Logger.Log([LogMessage]::new("[RoleManager:LoadState] Loading role/user mapping state from storage"), [LogType]::System)
            $this.RoleUserMapping = $mappingConfig
        }
    }

    [Role]GetRole([string]$RoleName) {
        $r = $this.Roles[$RoleName]
        if ($r) {
            return $r
        } else {
            $msg = "[RoleManager:GetRole] Role [$RoleName] not found"
            $this._Logger.Log([LogMessage]::new($msg), [LogType]::System)
            Write-Error -Message $msg
            return $null
        }
    }

    [void]AddRole([Role]$Role) {
        if (-not $this.Roles.ContainsKey($Role.Name)) {
            $this._Logger.Log([LogMessage]::new("[RoleManager:AddRole] Adding role [$($Role.Name)]"), [LogType]::System)
            $this.Roles.Add($Role.Name, $Role)
            $this.SaveState()
        } else {
            $this._Logger.Log([LogMessage]::new("[RoleManager:AddRole] Role [$($Role.Name)] is already loaded"), [LogType]::System)
        }
    }

    [void]RemoveRole([Role]$Role) {
        if ($this.Roles.ContainsKey($Role.Name)) {
            $this._Logger.Log([LogMessage]::new("[RoleManager:RemoveRole] Removing role [$($Role.Name)]"), [LogType]::System)
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
                        if (-not $roleUsers.ContainsKey($UserId)) {
                            $this._Logger.Log([LogMessage]::new("[RoleManager:AddUserToRole] Adding [$UserId] to role [$RoleName]"), [LogType]::System)
                            $roleUsers.Add($UserId, $UserId)
                        }
                    } else {
                        $roleUsers = @{}
                        $this._Logger.Log([LogMessage]::new("[RoleManager:AddUserToRole] Adding [$UserId] to role [$RoleName]"), [LogType]::System)
                        $roleUsers.Add($UserId, $UserId)
                        $this.RoleUserMapping.Add($RoleName, $roleUsers)
                    }
                    $this.SaveState()
                } else {
                    $msg = "Unknown role [$RoleName]"
                    $this._Logger.Log([LogMessage]::new("[RoleManager:AddUserToRole] $msg"), [LogType]::System)
                    throw $msg
                }
            } else {
                $msg = "Unable to find user [$UserId]"
                $this._Logger.Log([LogMessage]::new("[RoleManager:AddUserToRole] $msg"), [LogType]::System)
                throw $msg
            }
        } catch {
            Write-Error $_
        }
    }

    [void]RemoveUserFromRole([string]$UserId, [string]$RoleName) {
        if ($role = $this.GetRole($RoleName)) {
            if ($roleUsers = $this.RoleUserMapping[$RoleName]) {
                if ($roleUsers.ContainsKey($UserId)) {
                    $this._Logger.Log([LogMessage]::new("[RoleManager:RemoveUserFromRole] Removing [$UserId] from role [$RoleName]"), [LogType]::System)
                    $roleUsers.Remove($UserId)
                    $this.SaveState()
                }
            }
        }
    }

    [bool]UserInRole([string]$UserId, [string]$RoleName) {
        if ($role = $this.GetRole($RoleName)) {
            if ($roleUsers = $this.RoleUserMapping[$RoleName]) {
                return $roleUsers.ContainsKey($UserId)
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
                $id = $name
            }
        }
        $this._Logger.Log([LogMessage]::new("[RoleManager:ResolveUserToId] Resolved [$Username] to [$id]"), [LogType]::System)
        return $id
    }
}
