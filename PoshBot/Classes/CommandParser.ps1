
class ParsedCommand {
    [string]$CommandString
    [string]$Plugin = $null
    [string]$Command = $null
    [string]$Version = $null
    [string[]]$Tokens = @()
    [hashtable]$NamedParameters = @{}
    [System.Collections.ArrayList]$PositionalParameters = (New-Object System.Collections.ArrayList)
    [datetime]$Time = (Get-Date).ToUniversalTime()
    [string]$From = $null
    [string]$To = $null
    [Message]$OriginalMessage

    [pscustomobject]Summarize() {
        $o = $this | Select-Object -Property * -ExcludeProperty NamedParameters
        if ($this.Plugin -eq 'Builtin') {
            $np = $this.NamedParameters.GetEnumerator() | Where-Object {$_.Name -ne 'Bot'}
            $o | Add-Member -MemberType NoteProperty -Name NamedParameters -Value $np
        } else {
            $o | Add-Member -MemberType NoteProperty -Name NamedParameters -Value $this.NamedParameters
        }
        return [pscustomobject]$o
    }
}

class CommandParser {
    [ParsedCommand] static Parse([Message]$Message) {

        $commandString = [string]::Empty
        if (-not [string]::IsNullOrEmpty($Message.Text)) {
            $commandString = $Message.Text.Trim()
        }

        # The command is the first word of the message
        $command = $commandString.Split(' ')[0]

        # The first word of the message COULD be a URI, don't try and parse than into a command
        if ($command -notlike '*://*') {
            $arrCmdStr = $command.Split(':')
        } else {
            $arrCmdStr = @($command)
        }

        # Check if a specific version of the command was specified
        $version = $null
        if ($arrCmdStr[1] -as [Version]) {
            $version = $arrCmdStr[1]
        } elseif ($arrCmdStr[2] -as [Version]) {
            $version = $arrCmdStr[2]
        }

        # The command COULD be in the form of <command> or <plugin:command>
        # Figure out which one
        $plugin = [string]::Empty
        if ($Message.Type -eq [MessageType]::Message -and $Message.SubType -eq [MessageSubtype]::None ) {
            $plugin = $arrCmdStr[0]
        }
        if ($arrCmdStr[1] -as [Version]) {
            $command = $arrCmdStr[0]
            $plugin = $null
        } else {
            $command = $arrCmdStr[1]
            if (-not $command) {
                $command = $plugin
                $plugin = $null
            }
        }


        # Create the ParsedCommand instance
        $parsedCommand = [ParsedCommand]::new()
        $parsedCommand.CommandString = $commandString
        $parsedCommand.Plugin = $plugin
        $parsedCommand.Command = $command
        $parsedCommand.OriginalMessage = $Message
        $parsedCommand.Time = $Message.Time
        if ($version)      { $parsedCommand.Version = $version }
        if ($Message.To)   { $parsedCommand.To      = $Message.To }
        if ($Message.From) { $parsedCommand.From    = $Message.From }

        # Parse the message text using AST into named and positional parameters
        try {
            $positionalParams = @()
            $namedParams = @{}

            if (-not [string]::IsNullOrEmpty($commandString)) {
                # Replace '--<ParamName>' with '-<ParamName' so AST works
                $astCmdStr = $commandString -replace '(--([a-zA-Z]))', '-$2'
                $ast = [System.Management.Automation.Language.Parser]::ParseInput($astCmdStr, [ref]$null, [ref]$null)
                $commandAST = $ast.FindAll({$args[0] -as [System.Management.Automation.Language.CommandAst]},$false)

                for ($x = 1; $x -lt $commandAST.CommandElements.Count; $x++) {

                    $element = $commandAST.CommandElements[$x]

                    if ($element -is [System.Management.Automation.Language.CommandParameterAst]) {

                        $paramName = $element.ParameterName
                        $paramValues = @()
                        $y = 1

                        # If the element after this one is another CommandParameterAst or this
                        # is the last element then assume this parameter is a [switch]
                        if ((-not $commandAST.CommandElements[$x+1]) -or ($commandAST.CommandElements[$x+1] -is [System.Management.Automation.Language.CommandParameterAst])) {
                            $paramValues = $true
                        } else {
                            # Inspect the elements immediately after this CommandAst as they are values
                            # for a named parameter and pull out the values (array, string, bool, etc)
                            do {
                                $paramValues += $commandAST.CommandElements[$x+$y].SafeGetValue()
                                $y++
                            } until ((-not $commandAST.CommandElements[$x+$y]) -or $commandAST.CommandElements[$x+$y] -is [System.Management.Automation.Language.CommandParameterAst])
                        }

                        if ($paramValues.Count -eq 1) {
                            $paramValues = $paramValues[0]
                        }
                        $namedParams.Add($paramName, $paramValues)
                        $x += $y-1
                    } else {
                        # This element is a positional parameter value so just get the value
                        $positionalParams += $element.SafeGetValue()
                    }
                }
            }

            $parsedCommand.NamedParameters = $namedParams
            $parsedCommand.PositionalParameters = $positionalParams
        } catch {
            Write-Error -Message "Error parsing command [$CommandString]: $_"
        }

        return $parsedCommand
    }
}
