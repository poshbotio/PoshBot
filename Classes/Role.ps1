
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

    # Role([string]$Name, [string[]]$Users) {
    #     $this.Name = $Name
    #     $this.AddMembers($Users)
    # }

    # Role([string]$Name, [string]$Description, [string[]]$Users) {
    #     $this.Name = $Name
    #     $this.Description = $Description
    #     $this.AddMembers($Users)
    # }

    # [bool]IsMember([string]$Id) {
    #     return $this.Members.ContainsKey($Id)
    # }

    # [void]AddUsers([string[]]$UsersIds) {
    #     foreach ($user in $UsersIds) {
    #         if (-not $this.Members.ContainsKey($user)) {
    #             $this.Members.add($user, $null)
    #         }
    #     }
    # }

    # [void]RemoveUsers([string[]]$UsersIds) {
    #     foreach ($user in $UsersIds) {
    #         if ($this.Members.ContainsKey($user)) {
    #             $this.Members.Remove($user)
    #         }
    #     }
    # }
}
