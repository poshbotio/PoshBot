# The Plugin class holds a collection of related commands that came
# from a PowerShell module

# Some custom exceptions dealing with plugins
class PluginException : Exception {
    PluginException() {}
    PluginException([string]$Message) : base($Message) {}
}

class PluginNotFoundException : PluginException {
    PluginNotFoundException() {}
    PluginNotFoundException([string]$Message) : base($Message) {}
}

class PluginDisabled : PluginException {
    PluginDisabled() {}
    PluginDisabled([string]$Message) : base($Message) {}
}

# Represents a fully qualified module command
class ModuleCommand {
    [string]$Module
    [string]$Command

    [string]ToString() {
        return "$($this.Module)\$($this.Command)"
    }
}

class Plugin {

    # Unique name for the plugin
    [string]$Name

    # Commands bundled with plugin
    [hashtable]$Commands = @{}

    [version]$Version

    [bool]$Enabled

    [hashtable]$Permissions = @{}

    hidden [string]$_ManifestPath

    Plugin() {
        $this.Name = $this.GetType().Name
        $this.Enabled = $true
    }

    Plugin([string]$Name) {
        $this.Name = $Name
        $this.Enabled = $true
    }

    # Find the command
    [Command]FindCommand([Command]$Command) {
        return $this.Commands.($Command.Name)
    }

    # Add a PowerShell module to the plugin
    [void]AddModule([string]$ModuleName) {
        if (-not $this.Modules.ContainsKey($ModuleName)) {
            $this.Modules.Add($ModuleName, $null)
            $this.LoadModuleCommands($ModuleName)
        }
    }

    # Add a new command
    [void]AddCommand([Command]$Command) {
        if (-not $this.FindCommand($Command)) {
            $this.Commands.Add($Command.Name, $Command)
        }
    }

    # Remove an existing command
    [void]RemoveCommand([Command]$Command) {
        $existingCommand = $this.FindCommand($Command)
        if ($existingCommand) {
            $this.Commands.Remove($Command.Name)
        }
    }

    # Activate a command
    [void]ActivateCommand([Command]$Command) {
        $existingCommand = $this.FindCommand($Command)
        if ($existingCommand) {
            $existingCommand.Activate()
        }
    }

    # Deactivate a command
    [void]DeactivateCommand([Command]$Command) {
        $existingCommand = $this.FindCommand($Command)
        if ($existingCommand) {
            $existingCommand.Deactivate()
        }
    }

    [void]AddPermission([Permission]$Permission) {
        if (-not $this.Permissions.ContainsKey($Permission.ToString())) {
            $this.Permissions.Add($Permission.ToString(), $Permission)
        }
    }

    [Permission]GetPermission([string]$Name) {
        return $this.Permissions[$Name]
    }

    [void]RemovePermission([Permission]$Permission) {
        if ($this.Permissions.ContainsKey($Permission.ToString())) {
            $this.Permissions.Remove($Permission.ToString())
        }
    }

    # Activate plugin and all commands
    [void]Activate() {
        $this.Enabled = $true
        $this.Commands.GetEnumerator() | ForEach-Object {
            $_.Value.Activate()
        }
    }

    # Deactivate plugin and all commands
    [void]Deactivate() {
        $this.Enabled = $false
        $this.Commands.GetEnumerator() | ForEach-Object {
            $_.Value.Deactivate()
        }
    }

    [hashtable]ToHash() {
        $cmdPerms = @{}
        $this.Commands.GetEnumerator() | Foreach-Object {
            $cmdPerms.Add($_.Name, $_.Value.AccessFilter.Permissions.Keys)
        }

        $adhocPerms = @{}
        $this.Permissions.GetEnumerator() | Where-Object {$_.Value.Adhoc -eq $true} | Foreach-Object {
            $adhocPerms.Add($_.Name, $null)
        }
        return @{
            Name = $this.Name
            Version = $this.Version.ToString()
            Enabled = $this.Enabled
            ManifestPath = $this._ManifestPath
            CommandPermissions = $cmdPerms
            AdhocPermissions = $adhocPerms
        }
    }
}
