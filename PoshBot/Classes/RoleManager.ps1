
class RoleManager : BaseLogger {
    [hashtable]$Groups = @{}
    [hashtable]$Permissions = @{}
    [hashtable]$Roles = @{}
    [hashtable]$RoleUserMapping = @{}
    hidden [object]$_Backend
    hidden [StorageProvider]$_Storage
    hidden [string[]]$_AdminPermissions = @('manage-roles', 'show-help' ,'view', 'view-role', 'view-group',
                                           'manage-plugins', 'manage-groups', 'manage-permissions', 'manage-schedules')

    RoleManager([object]$Backend, [StorageProvider]$Storage, [Logger]$Logger) {
        $this._Backend = $Backend
        $this._Storage = $Storage
        $this.Logger = $Logger
        $this.Initialize()
    }

    [void]Initialize() {
        # Load in state from persistent storage
        $this.LogInfo('Initializing')

        $this.LoadState()

        # Create the initial state of the [Admin] role ONLY if it didn't get loaded from storage
        # This could be because this is the first time the bot has run and [roles.psd1] doesn't exist yet.
        # The bot admin could have modified the permissions for the role and we want to respect those changes
        if (-not $this.Roles['Admin']) {
            # Create the builtin Admin role and add all the permissions defined in the [Builtin] module
            $this.LogDebug('Creating builtin [Admin] role')
            $adminrole = [Role]::New('Admin', 'Bot administrator role', $this.Logger)

            # TODO
            # Get the builtin permissions from the module manifest rather than hard coding them in the class
            $this._AdminPermissions | foreach-object {
                $p = [Permission]::new($_, 'Builtin')
                $adminRole.AddPermission($p)
            }
            $this.LogDebug('Added builtin permissions to [Admin] role', $this._AdminPermissions)
            $this.Roles.Add($adminRole.Name, $adminRole)

            # Creat the builtin [Admin] group and add the [Admin] role to it
            $this.LogDebug('Creating builtin [Admin] group with [Admin] role')
            $adminGroup = [Group]::new('Admin', 'Bot administrators', $this.Logger)
            $adminGroup.AddRole($adminRole)
            $this.Groups.Add($adminGroup.Name, $adminGroup)
            $this.SaveState()
        } else {
            # Make sure all the admin permissions are added to the 'Admin' role
            # This is so if we need to add any permissions in future versions, they will automatically
            # be added to the role
            $adminRole = $this.Roles['Admin']
            foreach ($perm in $this._AdminPermissions) {
                if (-not $adminRole.Permissions.ContainsKey($perm)) {
                    $this.LogInfo("[Admin] role missing builtin permission [$perm]. Adding permission back.")
                    $p = [Permission]::new($perm, 'Builtin')
                    $adminRole.AddPermission($p)
                }
            }
        }
    }

    # Save state to storage
    [void]SaveState() {
        $this.LogDebug('Saving role manager state to storage')

        $permissionsToSave = @{}
        foreach ($permission in $this.Permissions.GetEnumerator()) {
            $permissionsToSave.Add($permission.Name, $permission.Value.ToHash())
        }
        $this._Storage.SaveConfig('permissions', $permissionsToSave)

        $rolesToSave = @{}
        foreach ($role in $this.Roles.GetEnumerator()) {
            $rolesToSave.Add($role.Name, $role.Value.ToHash())
        }
        $this._Storage.SaveConfig('roles', $rolesToSave)

        $groupsToSave = @{}
        foreach ($group in $this.Groups.GetEnumerator()) {
            $groupsToSave.Add($group.Name, $group.Value.ToHash())
        }
        $this._Storage.SaveConfig('groups', $groupsToSave)
    }

    # Load state from storage
    [void]LoadState() {
        $this.LogDebug('Loading role manager state from storage')

        $permissionConfig = $this._Storage.GetConfig('permissions')
        if ($permissionConfig) {
            foreach($permKey in $permissionConfig.Keys) {
                $perm = $permissionConfig[$permKey]
                $p = [Permission]::new($perm.Name, $perm.Plugin)
                if ($perm.Adhoc) {
                    $p.Adhoc = $perm.Adhoc
                }
                if ($perm.Description) {
                    $p.Description = $perm.Description
                }
                if (-not $this.Permissions.ContainsKey($p.ToString())) {
                    $this.Permissions.Add($p.ToString(), $p)
                }
            }
        }

        $roleConfig = $this._Storage.GetConfig('roles')
        if ($roleConfig) {
            foreach ($roleKey in $roleConfig.Keys) {
                $role = $roleConfig[$roleKey]
                $r = [Role]::new($roleKey, $this.Logger)
                if ($role.Description) {
                    $r.Description = $role.Description
                }
                if ($role.Permissions) {
                    foreach ($perm in $role.Permissions) {
                        if ($p = $this.Permissions[$perm]) {
                            $r.AddPermission($p)
                        }
                    }
                }
                if (-not $this.Roles.ContainsKey($r.Name)) {
                    $this.Roles.Add($r.Name, $r)
                }
            }
        }

        $groupConfig = $this._Storage.GetConfig('groups')
        if ($groupConfig) {
            foreach ($groupKey in $groupConfig.Keys) {
                $group = $groupConfig[$groupKey]
                $g = [Group]::new($groupKey, $this.Logger)
                if ($group.Description) {
                    $g.Description = $group.Description
                }
                if ($group.Users) {
                    foreach ($u in $group.Users) {
                        $g.AddUser($u)
                    }
                }
                if ($group.Roles) {
                    foreach ($r in $group.Roles) {
                        if ($ro = $this.GetRole($r)) {
                            $g.AddRole($ro)
                        }
                    }
                }
                if (-not $this.Groups.ContainsKey($g.Name)) {
                    $this.Groups.Add($g.Name, $g)
                }
            }
        }
    }

    [Group]GetGroup([string]$Groupname) {
        if ($g = $this.Groups[$Groupname]) {
            return $g
        } else {
            $this.LogInfo([LogSeverity]::Warning, "Group [$Groupname] not found")
            return $null
        }
    }

    [void]UpdateGroupDescription([string]$Groupname, [string]$Description) {
        if ($g = $this.Groups[$Groupname]) {
            $g.Description = $Description
            $this.SaveState()
        } else {
            $this.LogInfo([LogSeverity]::Warning, "Group [$Groupname] not found")
        }
    }

    [void]UpdateRoleDescription([string]$Rolename, [string]$Description) {
        if ($r = $this.Roles[$Rolename]) {
            $r.Description = $Description
            $this.SaveState()
        } else {
            $this.LogInfo([LogSeverity]::Warning, "Role [$Rolename] not found")
        }
    }

    [Permission]GetPermission([string]$PermissionName) {
        $p = $this.Permissions[$PermissionName]
        if ($p) {
            return $p
        } else {
            $this.LogInfo([LogSeverity]::Warning, "Permission [$PermissionName] not found")
            return $null
        }
    }

    [Role]GetRole([string]$RoleName) {
        $r = $this.Roles[$RoleName]
        if ($r) {
            return $r
        } else {
            $this.LogInfo([LogSeverity]::Warning, "Role [$RoleName] not found")
            return $null
        }
    }

    [void]AddGroup([Group]$Group) {
        if (-not $this.Groups.ContainsKey($Group.Name)) {
            $this.LogVerbose("Adding group [$($Group.Name)]")
            $this.Groups.Add($Group.Name, $Group)
            $this.SaveState()
        } else {
            $this.LogInfo([LogSeverity]::Warning, "Group [$($Group.Name)] is already loaded")
        }
    }

    [void]AddPermission([Permission]$Permission) {
        if (-not $this.Permissions.ContainsKey($Permission.ToString())) {
            $this.LogVerbose("Adding permission [$($Permission.Name)]")
            $this.Permissions.Add($Permission.ToString(), $Permission)
            $this.SaveState()
        } else {
            $this.LogInfo([LogSeverity]::Warning, "Permission [$($Permission.Name)] is already loaded")
        }
    }

    [void]AddRole([Role]$Role) {
        if (-not $this.Roles.ContainsKey($Role.Name)) {
            $this.LogVerbose("Adding role [$($Role.Name)]")
            $this.Roles.Add($Role.Name, $Role)
            $this.SaveState()
        } else {
            $this.LogInfo([LogSeverity]::Warning, "Role [$($Role.Name)] is already loaded")
        }
    }

    [void]RemoveGroup([Group]$Group) {
        if ($this.Groups.ContainsKey($Group.Name)) {
            $this.LogVerbose("Removing group [$($Group.Name)]")
            $this.Groups.Remove($Group.Name)
            $this.SaveState()
        } else {
            $this.LogInfo([LogSeverity]::Warning, "Group [$($Group.Name)] was not found")
        }
    }

    [void]RemovePermission([Permission]$Permission) {
        if (-not $this.Permissions.ContainsKey($Permission.ToString())) {
            # Remove the permission from roles
            foreach ($role in $this.Roles.GetEnumerator()) {
                if ($role.Value.Permissions.ContainsKey($Permission.ToString())) {
                    $this.LogVerbose("Removing permission [$($Permission.ToString())] from role [$($role.Value.Name)]")
                    $role.Value.RemovePermission($Permission)
                }
            }

            $this.LogVerbose("Removing permission [$($Permission.ToString())]")
            $this.Permissions.Remove($Permission.ToString())
            $this.SaveState()
        } else {
            $this.LogInfo([LogSeverity]::Warning, "Permission [$($Permission.ToString())] was not found")
        }
    }

    [void]RemoveRole([Role]$Role) {
        if ($this.Roles.ContainsKey($Role.Name)) {
            # Remove the role from groups
            foreach ($group in $this.Groups.GetEnumerator()) {
                if ($group.Value.Roles.ContainsKey($Role.Name)) {
                    $this.LogVerbose("Removing role [$($Role.Name)] from group [$($group.Value.Name)]")
                    $group.Value.RemoveRole($Role)
                }
            }

            $this.LogVerbose("Removing role [$($Role.Name)]")
            $this.Roles.Remove($Role.Name)
            $this.SaveState()
        } else {
            $this.LogInfo([LogSeverity]::Warning, "Role [$($Role.Name)] was not found")
        }
    }

    [void]AddRoleToGroup([string]$RoleName, [string]$GroupName) {
        try {
            if ($role = $this.GetRole($RoleName)) {
                if ($group = $this.Groups[$GroupName]) {
                    $this.LogVerbose("Adding role [$RoleName] to group [$($group.Name)]")
                    $group.AddRole($role)
                    $this.SaveState()
                } else {
                    $msg = "Unknown group [$GroupName]"
                    $this.LogInfo([LogSeverity]::Warning, $msg)
                    throw $msg
                }
            } else {
                $msg = "Unable to find role [$RoleName]"
                $this.LogInfo([LogSeverity]::Warning, $msg)
                throw $msg
            }
        } catch {
            throw $_
        }
    }

    [void]AddUserToGroup([string]$UserId, [string]$GroupName) {
        try {
            if ($this._Backend.GetUser($UserId)) {
                if ($group = $this.Groups[$GroupName]) {
                    $this.LogVerbose("Adding user [$UserId] to [$($group.Name)]")
                    $group.AddUser($UserId)
                    $this.SaveState()
                } else {
                    $msg = "Unknown group [$GroupName]"
                    $this.LogInfo([LogSeverity]::Warning, $msg)
                    throw $msg
                }
            } else {
                $msg = "Unable to find user [$UserId]"
                $this.LogInfo([LogSeverity]::Warning, $msg)
                throw $msg
            }
        } catch {
            $this.LogInfo([LogSeverity]::Error, "Exception adding [$UserId] to [$GroupName]", $_)
            throw $_
        }
    }

    [void]RemoveRoleFromGroup([string]$RoleName, [string]$GroupName) {
        try {
            if ($role = $this.GetRole($RoleName)) {
                if ($group = $this.Groups[$GroupName]) {
                    $this.LogVerbose("Removing role [$RoleName] from group [$($group.Name)]")
                    $group.RemoveRole($role)
                    $this.SaveState()
                } else {
                    $msg = "Unknown group [$GroupName]"
                    $this.LogInfo([LogSeverity]::Warning, $msg)
                    throw $msg
                }
            } else {
                $msg = "Unable to find role [$RoleName]"
                $this.LogInfo([LogSeverity]::Warning, $msg)
                throw $msg
            }
        } catch {
            $this.LogInfo([LogSeverity]::Error, "Exception removing [$RoleName] from [$GroupName]", $_)
            throw $_
        }
    }

    [void]RemoveUserFromGroup([string]$UserId, [string]$GroupName) {
        try {
            if ($group = $this.Groups[$GroupName]) {
                if ($group.Users.ContainsKey($UserId)) {
                    $this.LogVerbose("Removing user [$UserId] from group [$($group.Name)]")
                    $group.RemoveUser($UserId)
                    $this.SaveState()
                }
            } else {
                $msg = "Unknown group [$GroupName]"
                $this.LogInfo([LogSeverity]::Warning, $msg)
                throw $msg
            }
        } catch {
            $this.LogInfo([LogSeverity]::Error, "Exception removing [$UserId] from [$GroupName]", $_)
            throw $_
        }
    }

    [void]AddPermissionToRole([string]$PermissionName, [string]$RoleName) {
        try {
            if ($role = $this.GetRole($RoleName)) {
                if ($perm = $this.Permissions[$PermissionName]) {
                    $this.LogVerbose("Adding permission [$PermissionName] to role [$($role.Name)]")
                    $role.AddPermission($perm)
                    $this.SaveState()
                } else {
                    $msg = "Unknown permission [$perm]"
                    $this.LogInfo([LogSeverity]::Warning, $msg)
                    throw $msg
                }
            } else {
                $msg = "Unable to find role [$RoleName]"
                $this.LogInfo([LogSeverity]::Warning, $msg)
                throw $msg
            }
        } catch {
            $this.LogInfo([LogSeverity]::Error, "Exception adding [$PermissionName] to [$RoleName]", $_)
            throw $_
        }
    }

    [void]RemovePermissionFromRole([string]$PermissionName, [string]$RoleName) {
        try {
            if ($role = $this.GetRole($RoleName)) {
                if ($perm = $this.Permissions[$PermissionName]) {
                    $this.LogVerbose("Removing permission [$PermissionName] from role [$($role.Name)]")
                    $role.RemovePermission($perm)
                    $this.SaveState()
                } else {
                    $msg = "Unknown permission [$PermissionName]"
                    $this.LogInfo([LogSeverity]::Warning, $msg)
                    throw $msg
                }
            } else {
                $msg = "Unable to find role [$RoleName]"
                $this.LogInfo([LogSeverity]::Warning, $msg)
                throw $msg
            }
        } catch {
            $this.LogInfo([LogSeverity]::Error, "Exception removing [$PermissionName] from [$RoleName]", $_)
            throw $_
        }
    }

    [Group[]]GetUserGroups([string]$UserId) {
        $userGroups = New-Object System.Collections.ArrayList

        foreach ($group in $this.Groups.GetEnumerator()) {
            if ($group.Value.Users.ContainsKey($UserId)) {
                $userGroups.Add($group.Value)
            }
        }
        return $userGroups
    }

    [Role[]]GetUserRoles([string]$UserId) {
        $userRoles = New-Object System.Collections.ArrayList

        foreach ($group in $this.GetUserGroups($UserId)) {
            foreach ($role in $group.Roles.GetEnumerator()) {
                $userRoles.Add($role.Value)
            }
        }

        return $userRoles
    }

    [Permission[]]GetUserPermissions([string]$UserId) {
        $userPermissions = New-Object System.Collections.ArrayList

        if ($userRoles = $this.GetUserRoles($UserId)) {
            foreach ($role in $userRoles) {
                $userPermissions.AddRange($role.Permissions.Keys)
            }
        }

        return $userPermissions
    }

    # Resolve a username to their Id
    [string]ResolveUserIdToUserName([string]$Id) {
        return $this._Backend.UserIdToUsername($Id)
    }

    [string]ResolveUsernameToId([string]$Username) {
        return $this._Backend.UsernameToUserId($Username)
    }
}
