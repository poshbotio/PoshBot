
class CommandAuthorizationResult {
    [bool]$Authorized
    [string]$Message

    CommandAuthorizationResult() {
        $this.Authorized = $true
    }

    CommandAuthorizationResult([bool]$Authorized) {
        $this.Authorized = $Authorized
    }

    CommandAuthorizationResult([bool]$Authorized, [string]$Message) {
        $this.Authorized = $Authorized
        $this.Message = $Message
    }
}

# An access filter controls under what conditions a command can be run and who can run it.
class AccessFilter {

    # Allow command only from users in these roles
    # [hashtable]$AllowRoles = @{}

    # [hashtable]$DenyRoles = @{}

    [hashtable]$Permissions = @{}

    # Allow command only from these users (or from users in AllowRoles)
    # [hashtable]$AllowUsers = @{}

    # Deny command to these users
    # [hashtable]$DenyUsers = @{}

    # Allow command only in these rooms
    # [hashtable]$AllowRooms = @{}

    # Deny command in these rooms
    # [hashtable]$DenyRooms = @{}

    # Allow command from DMs to the bot
    # [bool]$AllowPrivate = $true

    # Deny command from inside room (only allow DM)
    # [bool]$AllowChannel = $true

    [CommandAuthorizationResult]Authorize([string]$PermissionName) {
        if ($this.Permissions.Count -eq 0) {
            return $true
        } else {
            if (-not $this.Permissions.ContainsKey($PermissionName)) {
                return [CommandAuthorizationResult]::new($false, "Permission [$PermissionName] is not authorized to execute this command")
            } else {
                return $true
            }
        }
    }

    # # Is a role authorized to run this command?
    # [CommandAuthorizationResult]AuthorizeRole([string]$Role) {

    #     if ($this.DenyRoles.ContainsKey($Role)) {
    #         return [CommandAuthorizationResult]::new($false, "Role [$Role] is not authorized to execute this command")
    #     }

    #     if (($this.AllowRoles.Count -gt 0) -and
    #        (-not $this.AllowRoles.ContainsKey($Role))) {
    #         return [CommandAuthorizationResult]::new($false, "Role [$Role] is not authorized to execute this command")
    #     }

    #     return [CommandAuthorizationResult]::new($true)
    # }

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

    # [CommandAuthorizationResult]AuthorizeUser([string]$UserId) {

    #     if ($this.DenyUsers.ContainsKey($UserId)) {
    #         return [CommandAuthorizationResult]::new($false, "User [$UserId] is not authorized to execute this command")
    #     }

    #     if (($this.AllowUsers.Count -gt 0) -and
    #        (-not $this.AllowUsers.ContainsKey($UserId))) {
    #         return [CommandAuthorizationResult]::new($false, "User [$UserId] is not authorized to execute this command")
    #     }

    #     return [CommandAuthorizationResult]::new($true)
    # }

    # # Is a user, room or DM allowed to run this command?
    # [CommandAuthorizationResult]Authorize([string]$UserId, [string]$RoomId, [bool]$IsDM) {

    #     # User is explicitly denied or not in explicit allowed list
    #     if ($this.DenyUsers.ContainsKey($UserId) -or
    #        ($this.AllowUsers.Count -gt 0) -and (-not $this.AllowUsers.ContainsKey($UserId))) {
    #         return [CommandAuthorizationResult]::new($false, "User [$UserId] is not authorized to execute this command")
    #     }

    #     # Room is explicitly denied or not in explicit allowed list
    #     if ($this.DenyRooms.ContainsKey($RoomId) -or
    #        ($this.AllowRooms.Count -gt 0) -and (-not $this.AllowRooms.ContainsKey($RoomId))) {
    #         return [CommandAuthorizationResult]::new($false, "Command now allowed in room [$RoomId]")
    #     }

    #     # DMs not allowed but tried to execute command from DM
    #     if ((-not $this.AllowPrivate) -and $IsDM ) {
    #         return [CommandAuthorizationResult]::new($false, "Command not allowed in direct messages")
    #     }

    #     # Execute from channel not allowed and isn't a DM
    #     if ((-not $this.AllowChannel) -and (-not $IsDM)) {
    #         return [CommandAuthorizationResult]::new($false, "Command not allowed in channels")
    #     }

    #     # Explicit list of users allowed and user isn't in list
    #     if (($this.AllowUsers.Count -gt 0) -and
    #        (-not $this.AllowUsers.ContainsKey($UserId))) {
    #         return [CommandAuthorizationResult]::new($false, "Command not allowed in channels")
    #     }

    #     # If we got this far, the command is allowed
    #     return [CommandAuthorizationResult]::new($true)
    # }

    # [void]AddAllowedRole([string]$Role) {
    #     if (-not $this.AllowRoles.ContainsKey($Role)) {
    #         $this.AllowRoles.Add($Role, $null)
    #     }
    # }

    # [void]RemoveAllowedRole([string]$Role) {
    #     if ($this.AllowRoles.ContainsKey($Role)) {
    #         $this.AllowRoles.Remove($Role)
    #     }
    # }

    # [void]AddDeniedRole([string]$Role) {
    #     if (-not $this.DenyRoles.ContainsKey($Role)) {
    #         $this.DenyRoles.Add($Role, $null)
    #     }
    #     if ($this.AllowRoles.ContainsKey($Role)) {
    #         $this.AllowRoles.Remove($Role)
    #     }
    # }

    # [void]RemoveDeniedRole([string]$Role) {
    #     if ($this.DenyRoles.ContainsKey($Role)) {
    #         $this.DenyRoles.Remove($Role)
    #     }
    # }

    # [void]AddAllowedUser([string]$UserId) {
    #     if (-not $this.AllowUsers.ContainsKey($UserId)) {
    #         $this.AllowUsers.Add($UserId, $null)
    #     }
    # }

    # [void]RemoveAllowedUser([string]$UserId) {
    #     if ($this.AllowUsers.ContainsKey($UserId)) {
    #         $this.AllowUsers.Remove($UserId)
    #     }
    # }

    # [void]AddDeniedUser([string]$UserId) {
    #     if (-not $this.DenyUsers.ContainsKey($UserId)) {
    #         $this.DenyUsers.Add($UserId, $null)
    #     }
    #     if ($this.AllowUsers.ContainsKey($UserId)) {
    #         $this.AllowUsers.Remove($UserId)
    #     }
    # }

    # [void]RemoveDeniedUser([string]$UserId) {
    #     if ($this.DenyUsers.ContainsKey($UserId)) {
    #         $this.DenyUsers.Remove($UserId)
    #     }
    # }

    # [void]AddAllowedRoom([string]$RoomId) {
    #     if (-not $this.AllowRooms.ContainsKey($RoomId)) {
    #         $this.AllowRooms.Add($RoomId, $null)
    #     }
    # }

    # [void]RemoveAllowedRoom([string]$RoomId) {
    #     if ($this.AllowRooms.ContainsKey($RoomId)) {
    #         $this.AllowRooms.Remove($RoomId)
    #     }
    # }

    # [void]AddDeniedRoom([string]$RoomId) {
    #     if (-not $this.DenyRooms.ContainsKey($RoomId)) {
    #         $this.DenyRooms.Add($RoomId, $null)
    #     }
    #     if ($this.AllowRooms.ContainsKey($RoomId)) {
    #         $this.AllowRooms.Remove($RoomId)
    #     }
    # }

    # [void]RemoveDeniedRoom([string]$RoomId) {
    #     if ($this.DenyRooms.ContainsKey($RoomId)) {
    #         $this.DenyRooms.Remove($RoomId)
    #     }
    # }
}
