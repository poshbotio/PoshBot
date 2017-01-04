
class ParsedCommand {
    [string]$CommandString
    [string]$Plugin = $null
    [string]$Command = $null
    [string[]]$Tokens = @()
    [hashtable]$NamedParameters = @{}
    [object[]]$PositionalParameters = @()
    [System.Management.Automation.FunctionInfo]$ModuleCommand = $null

}

class CommandParser {
    [ParsedCommand] static Parse([string]$CommandString) {

        # The command COULD be in the form of <command> or <plugin:command>
        # Figure out which one
        $pluginCmd = $CommandString.Split(' ')[0]
        $plugin = $pluginCmd.Split(':')[0]
        $command = $pluginCmd.Split(':')[1]
        # Not fully qualified
        if (-not $command) {
            $command = $plugin
            $plugin = $null
        }

        $tokens = $CommandString | Get-StringToken
        $r = ConvertFrom-ParameterToken -Tokens $Tokens
        $parsedCommand = [ParsedCommand]::new()
        $parsedCommand.CommandString = $CommandString
        $parsedCommand.Plugin = $plugin
        $parsedCommand.Command = $command
        $parsedCommand.Tokens = $r.Tokens
        $parsedCommand.NamedParameters = $r.NamedParameters
        $parsedCommand.PositionalParameters = $r.PositionalParameters
        return $parsedCommand
    }
}
