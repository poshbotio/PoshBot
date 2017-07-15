
class RoleManager {
    [hashtable]$Groups = @{}
    [hashtable]$Permissions = @{}
    [hashtable]$Roles = @{}
    [hashtable]$RoleUserMapping = @{}
    hidden [object]$_Backend
    hidden [StorageProvider]$_Storage
    hidden [Logger]$_Logger
    hidden [string[]]$_AdminPermissions = @('manage-roles', 'show-help' ,'view', 'view-role', 'view-group',
                                           'manage-plugins', 'manage-groups', 'manage-permissions', 'manage-schedules')

    RoleManager([object]$Backend, [StorageProvider]$Storage, [Logger]$Logger) {
        $this._Backend = $Backend
        $this._Storage = $Storage
        $this._Logger = $Logger
        $this.Initialize()
    }

    [void]Initialize() {
        # Load in state from persistent storage
        $this._Logger.Info([LogMessage]::new('[RoleManager:Initialize] Initializing'))

        $this.LoadState()

        # Create the initial state of the [Admin] role ONLY if it didn't get loaded from storage
        # This could be because this is the first time the bot has run and [roles.psd1] doesn't exist yet.
        # The bot admin could have modified the permissions for the role and we want to respect those changes
        if (-not $this.Roles['Admin']) {
            # Create the builtin Admin role and add all the permissions defined in the [Builtin] module
            $adminrole = [Role]::New('Admin', 'Bot administrator role')

            # TODO
            # Get the builtin permissions from the module manifest rather than hard coding them in the class
            $this._AdminPermissions | foreach-object {
                $p = [Permission]::new($_, 'Builtin')
                $adminRole.AddPermission($p)
            }
            $this.Roles.Add($adminRole.Name, $adminRole)

            # Creat the builtin [Admin] group and add the [Admin] role to it
            $adminGroup = [Group]::new('Admin', 'Bot administrators')
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
                    $p = [Permission]::new($perm, 'Builtin')
                    $adminRole.AddPermission($p)
                }
            }
        }
    }

    # Save state to storage
    [void]SaveState() {
        $this._Logger.Verbose([LogMessage]::new("[RoleManager:SaveState] Saving role manager state to storage"))

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
        $this._Logger.Verbose([LogMessage]::new("[RoleManager:LoadState] Loading role manager state from storage"))

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
                $r = [Role]::new($roleKey)
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
                $g = [Group]::new($groupKey)
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
            $msg = "[RoleManager:GetGroup] Group [$Groupname] not found"
            $this._Logger.Info([LogMessage]::new([LogSeverity]::Warning, $msg))
            Write-Error -Message $msg
            return $null
        }
    }

    [void]UpdateGroupDescription([string]$Groupname, [string]$Description) {
        if ($g = $this.Groups[$Groupname]) {
            $g.Description = $Description
            $this.SaveState()
        } else {
            $msg = "[RoleManager:UpdateGroupDescription] Group [$Groupname] not found"
            $this._Logger.Info([LogMessage]::new([LogSeverity]::Warning, $msg))
            Write-Error -Message $msg
        }
    }

    [void]UpdateRoleDescription([string]$Rolename, [string]$Description) {
        if ($r = $this.Roles[$Rolename]) {
            $r.Description = $Description
            $this.SaveState()
        } else {
            $msg = "[RoleManager:UpdateRoleDescription] Role [$Rolename] not found"
            $this._Logger.Info([LogMessage]::new([LogSeverity]::Warning, $msg))
            Write-Error -Message $msg
        }
    }

    [Permission]GetPermission([string]$PermissionName) {
        $p = $this.Permissions[$PermissionName]
        if ($p) {
            return $p
        } else {
            $msg = "[RoleManager:GetPermission] Permission [$PermissionName] not found"
            $this._Logger.Info([LogMessage]::new([LogSeverity]::Warning, $msg))
            Write-Error -Message $msg
            return $null
        }
    }

    [Role]GetRole([string]$RoleName) {
        $r = $this.Roles[$RoleName]
        if ($r) {
            return $r
        } else {
            $msg = "[RoleManager:GetRole] Role [$RoleName] not found"
            $this._Logger.Info([LogMessage]::new([LogSeverity]::Warning, $msg))
            Write-Error -Message $msg
            return $null
        }
    }

    [void]AddGroup([Group]$Group) {
        if (-not $this.Groups.ContainsKey($Group.Name)) {
            $this._Logger.Info([LogMessage]::new("[RoleManager:AddGroup] Adding group [$($Group.Name)]"))
            $this.Groups.Add($Group.Name, $Group)
            $this.SaveState()
        } else {
            $this._Logger.Info([LogMessage]::new("[RoleManager:AddGroup] Group [$($Group.Name)] is already loaded"))
        }
    }

    [void]AddPermission([Permission]$Permission) {
        if (-not $this.Permissions.ContainsKey($Permission.ToString())) {
            $this._Logger.Info([LogMessage]::new("[RoleManager:AddPermission] Adding permission [$($Permission.Name)]"))
            $this.Permissions.Add($Permission.ToString(), $Permission)
            $this.SaveState()
        } else {
            $this._Logger.Info([LogMessage]::new("[RoleManager:AddPermission] Permission [$($Permission.Name)] is already loaded"))
        }
    }

    [void]AddRole([Role]$Role) {
        if (-not $this.Roles.ContainsKey($Role.Name)) {
            $this._Logger.Info([LogMessage]::new("[RoleManager:AddRole] Adding role [$($Role.Name)]"))
            $this.Roles.Add($Role.Name, $Role)
            $this.SaveState()
        } else {
            $this._Logger.Info([LogMessage]::new("[RoleManager:AddRole] Role [$($Role.Name)] is already loaded"))
        }
    }

    [void]RemoveGroup([Group]$Group) {
        if ($this.Groups.ContainsKey($Group.Name)) {
            $this._Logger.Info([LogMessage]::new("[RoleManager:RemoveGroup] Removing group [$($Group.Name)]"))
            $this.Groups.Remove($Group.Name)
            $this.SaveState()
        } else {
            $this._Logger.Info([LogMessage]::new([LogSeverity]::Warning, "[RoleManager:RemoveGroup] Group [$($Group.Name)] was not found"))
        }
    }

    [void]RemovePermission([Permission]$Permission) {
        if (-not $this.Permissions.ContainsKey($Permission.ToString())) {

            # Remove the permission from roles
            foreach ($role in $this.Roles.GetEnumerator()) {
                if ($role.Value.Permissions.ContainsKey($Permission.ToString())) {
                    $this._Logger.Info([LogMessage]::new("[RoleManager:RemovePermission] Removing permission [$($Permission.ToString())] from role [$($role.Value.Name)]"))
                    $role.Value.RemovePermission($Permission)
                }
            }

            $this._Logger.Info([LogMessage]::new("[RoleManager:RemoveGroup] Removing permission [$($Permission.ToString())]"))
            $this.Permissions.Remove($Permission.ToString())
            $this.SaveState()
        } else {
            $this._Logger.Info([LogMessage]::new([LogSeverity]::Warning, "[RoleManager:RemovePermission] Permission [$($Permission.ToString())] was not found"))
        }
    }

    [void]RemoveRole([Role]$Role) {
        if ($this.Roles.ContainsKey($Role.Name)) {

            # Remove the role from groups
            foreach ($group in $this.Groups.GetEnumerator()) {
                if ($group.Value.Roles.ContainsKey($Role.Name)) {
                    $this._Logger.Info([LogMessage]::new("[RoleManager:RemoveRole] Removing role [$($Role.Name)] from group [$($group.Value.Name)]"))
                    $group.Value.RemoveRole($Role)
                }
            }

            $this._Logger.Info([LogMessage]::new("[RoleManager:RemoveRole] Removing role [$($Role.Name)]"))
            $this.Roles.Remove($Role.Name)
            $this.SaveState()
        } else {
            $this._Logger.Info([LogMessage]::new([LogSeverity]::Warning, "[RoleManager:RemoveRole] Role [$($Role.Name)] was not found"))
        }
    }

    [void]AddRoleToGroup([string]$RoleName, [string]$GroupName) {
        try {
            if ($role = $this.GetRole($RoleName)) {
                if ($group = $this.Groups[$GroupName]) {
                    $msg = "Adding role [$RoleName] to group [$($group.Name)]"
                    $this._Logger.Info([LogMessage]::new("[RoleManager:AddRoleToGroup] $msg"))
                    $group.AddRole($role)
                    $this.SaveState()
                } else {
                    $msg = "Unknown group [$GroupName]"
                    $this._Logger.Info([LogMessage]::new([LogSeverity]::Warning, "[RoleManager:AddRoleToGroup] $msg"))
                    throw $msg
                }
            } else {
                $msg = "Unable to find role [$RoleName]"
                $this._Logger.Info([LogMessage]::new([LogSeverity]::Warning, "[RoleManager:AddRoleToGroup] $msg"))
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
                    $msg = "Adding user [$UserId] to [$($group.Name)]"
                    $this._Logger.Info([LogMessage]::new([LogSeverity]::Warning, "[RoleManager:AddUserToGroup] $msg"))
                    $group.AddUser($UserId)
                    $this.SaveState()
                } else {
                    $msg = "Unknown group [$GroupName]"
                    $this._Logger.Info([LogMessage]::new([LogSeverity]::Warning, "[RoleManager:AddUserToGroup] $msg"))
                    throw $msg
                }
            } else {
                $msg = "Unable to find user [$UserId]"
                $this._Logger.Info([LogMessage]::new([LogSeverity]::Warning, "[RoleManager:AddUserToGroup] $msg"))
                throw $msg
            }
        } catch {
            throw $_
        }
    }

    [void]RemoveRoleFromGroup([string]$RoleName, [string]$GroupName) {
        try {
            if ($role = $this.GetRole($RoleName)) {
                if ($group = $this.Groups[$GroupName]) {
                    $msg = "Removing role [$RoleName] from group [$($group.Name)]"
                    $this._Logger.Info([LogMessage]::new("[RoleManager:RemoveUserFromGroup] $msg"))
                    $group.RemoveRole($role)
                    $this.SaveState()
                } else {
                    $msg = "Unknown group [$GroupName]"
                    $this._Logger.Info([LogMessage]::new([LogSeverity]::Warning, "[RoleManager:RemoveUserFromGroup] $msg"))
                    throw $msg
                }
            } else {
                $msg = "Unable to find role [$RoleName]"
                $this._Logger.Info([LogMessage]::new([LogSeverity]::Warning, "[RoleManager:RemoveUserFromGroup] $msg"))
                throw $msg
            }
        } catch {
            throw $_
        }
    }

    [void]RemoveUserFromGroup([string]$UserId, [string]$GroupName) {
        try {
            if ($group = $this.Groups[$GroupName]) {
                if ($group.Users.ContainsKey($UserId)) {
                    $group.RemoveUser($UserId)
                    $this.SaveState()
                }
            } else {
                $msg = "Unknown group [$GroupName]"
                $this._Logger.Info([LogMessage]::new([LogSeverity]::Warning, "[RoleManager:RemoveUserFromGroup] $msg"))
                throw $msg
            }
        } catch {
            throw $_
        }
    }

    [void]AddPermissionToRole([string]$PermissionName, [string]$RoleName) {
        try {
            if ($role = $this.GetRole($RoleName)) {
                if ($perm = $this.Permissions[$PermissionName]) {
                    $msg = "Adding permission [$PermissionName] to role [$($role.Name)]"
                    $this._Logger.Info([LogMessage]::new("[RoleManager:AddPermissionToRole] $msg"))
                    $role.AddPermission($perm)
                    $this.SaveState()
                } else {
                    $msg = "Unknown permission [$perm]"
                    $this._Logger.Info([LogMessage]::new([LogSeverity]::Warning, "[RoleManager:AddPermissionToRole] $msg"))
                    throw $msg
                }
            } else {
                $msg = "Unable to find role [$RoleName]"
                $this._Logger.Info([LogMessage]::new([LogSeverity]::Warning, "[RoleManager:AddPermissionToRole] $msg"))
                throw $msg
            }
        } catch {
            throw $_
        }
    }

    [void]RemovePermissionFromRole([string]$PermissionName, [string]$RoleName) {
        try {
            if ($role = $this.GetRole($RoleName)) {
                if ($perm = $this.Permissions[$PermissionName]) {
                    $msg = "Removing permission [$PermissionName] from role [$($role.Name)]"
                    $this._Logger.Info([LogMessage]::new("[RoleManager:RemovePermissionFromRole] $msg"))
                    $role.RemovePermission($perm)
                    $this.SaveState()
                } else {
                    $msg = "Unknown permission [$PermissionName]"
                    $this._Logger.Info([LogMessage]::new([LogSeverity]::Warning, "[RoleManager:RemovePermissionFromRole] $msg"))
                    throw $msg
                }
            } else {
                $msg = "Unable to find role [$RoleName]"
                $this._Logger.Info([LogMessage]::new([LogSeverity]::Warning, "[RoleManager:RemovePermissionFromRole] $msg"))
                throw $msg
            }
        } catch {
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
