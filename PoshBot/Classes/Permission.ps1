
class Permission {
    [string]$Name
    [string]$Plugin
    [string]$Description

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

    [string]ToString() {
        return "$($this.Plugin):$($this.Name)"
    }
}
