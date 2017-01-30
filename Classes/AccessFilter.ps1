
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

    [hashtable]$Permissions = @{}

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
