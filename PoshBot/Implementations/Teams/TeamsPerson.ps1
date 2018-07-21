class TeamsPerson : Person {
    [string]$Email
    [string]$UserPrincipalName

    [hashtable]ToHash() {
        $hash = @{}
        $this | Get-Member -MemberType Property | Foreach-Object {
            $hash.Add($_.Name, $this.($_.name))
        }
        return $hash
    }
}
