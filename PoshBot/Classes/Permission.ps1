
class Permission {
    [string]$Name
    [string]$Plugin
    [string]$Description
    [bool]$Adhoc = $false

    Permission([string]$Name) {
        $this.Name = $Name
    }

    Permission([string]$Name, [string]$Plugin) {
        $this.Name = $Name
        $this.Plugin = $Plugin
    }

    Permission([string]$Name, [string]$Plugin, [string]$Description) {
        $this.Name = $Name
        $this.Plugin = $Plugin
        $this.Description = $Description
    }

    [hashtable]ToHash() {
        return @{
            Name = $this.Name
            Plugin = $this.Plugin
            Description = $this.Description
            Adhoc = $this.Adhoc
        }
    }

    [string]ToString() {
        return "$($this.Plugin):$($this.Name)"
    }
}
