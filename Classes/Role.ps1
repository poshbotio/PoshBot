
class Role {
    [string]$Name
    [string]$Description
    #[hashtable]$Members = @{}

    Role([string]$Name) {
        $this.Name = $Name
    }

    Role([string]$Name, [string]$Description) {
        $this.Name = $Name
        $this.Description = $Description
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

function New-PoshBotRole {
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        [string]$Name,

        [ValidateNotNullOrEmpty]
        [string]$Description

        # [ValidateNotNull]
        # [string[]]$Members
    )

    $r = [Role]::new($Name)

    if ($PSBoundParameters.ContainsKey('Description')) {
        $r.Description = $Description
    }

    # if ($PSBoundParameters.ContainsKey('Members')) {
    #     $r.AddUsers($Members)
    # }

    return $r
}
