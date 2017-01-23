
class ParsedCommand {
    [string]$CommandString
    [string]$Plugin = $null
    [string]$Command = $null
    [string[]]$Tokens = @()
    [hashtable]$NamedParameters = @{}
    [System.Collections.ArrayList]$PositionalParameters = (New-Object System.Collections.ArrayList)
    #[System.Management.Automation.FunctionInfo]$ModuleCommand = $null
    [Message]$OriginalMessage
}

class CommandParser {
    [ParsedCommand] static Parse([string]$CommandString, [Message]$OriginalMessage) {

        $CommandString = $CommandString.Trim()

        # Everything to the left of a named parameter will be used
        # to determine the command name
        $command = ($CommandString -Split '--')[0]
        $params = $CommandString.TrimStart($command)

        # The command COULD be in the form of <command> or <plugin:command>
        # Figure out which one
        $plugin = [string]::Empty
        if ($OriginalMessage.Type -eq [MessageType]::Message -and $OriginalMessage.SubType -eq [MessageSubtype]::None ) {
            $plugin = $command.Split(':')[0]
        }
        $command = $command.Split(':')[1]
        if (-not $command) {
            $command = $plugin
            $plugin = $null
        }

        # Determine if we're trying to run a subcommand
        # and change command name to <primarycommand-subcommand>
        $arrCmd = $command.Split(' ')
        $primaryCmd = $arrCmd[0]
        $subCmd = $arrCmd[1]
        if ($subCmd) {
            $command = ($primaryCmd + '-' + $subCmd)
        } else {
            $command = $primaryCmd
        }

        $parsedCommand = [ParsedCommand]::new()
        $parsedCommand.CommandString = $CommandString
        $parsedCommand.Plugin = $plugin
        $parsedCommand.Command = $command
        $parsedCommand.OriginalMessage = $OriginalMessage

        # Parse parameters
        if (-not [string]::IsNullOrEmpty($params)) {
            $tokens = $CommandString | Get-StringToken
            try {
                $r = ConvertFrom-ParameterToken -Tokens $Tokens
                $parsedCommand.Tokens = $r.Tokens
                $parsedCommand.NamedParameters = $r.NamedParameters
            } catch {
                Write-Error "Error parsing command [$CommandString]: $_"
            }
        }

        return $parsedCommand
    }
}
