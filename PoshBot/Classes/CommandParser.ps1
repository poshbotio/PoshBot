
class CommandParser {
    [ParsedCommand] static Parse([Message]$Message,[string[]]$BotNames) {

        $commandString = [string]::Empty
        if (-not [string]::IsNullOrEmpty($Message.Text)) {
            $commandString = $Message.Text.Trim()
        }

        # LUISMODIFICATION: if the bot name appears in the command, CALL STP
        foreach ($BotName in $BotNames) {
            if ($commandString -like "*$($BotName)*") {
                #Remove the bot name from command
                $commandString = $commandString.Replace($BotName, '')
                continue
            }
        }

        # The command is the first word of the message
        $cmdArray = $commandString.Split(' ')
        $command = $cmdArray[0]
        if ($cmdArray.Count -gt 1) {
            $commandArgs = $cmdArray[1..($cmdArray.length-1)] -join ' '
        } else {
            $commandArgs = [string]::Empty
        }

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
        if ($version)          { $parsedCommand.Version  = $version }
        if ($Message.To)       { $parsedCommand.To       = $Message.To }
        if ($Message.ToName)   { $parsedCommand.ToName   = $Message.ToName }
        if ($Message.From)     { $parsedCommand.From     = $Message.From }
        if ($Message.FromName) { $parsedCommand.FromName = $Message.FromName }

        # Parse the message text using AST into named and positional parameters
        try {
            $positionalParams = @()
            $namedParams = @{}

            if (-not [string]::IsNullOrEmpty($commandArgs)) {

                # Create Abstract Syntax Tree of command string so we can parse out parameter names
                # and their values
                $astCmdStr = "fake-command $commandArgs" -Replace '(\s--([a-zA-Z0-9])*?)', ' -$2'
                $ast = [System.Management.Automation.Language.Parser]::ParseInput($astCmdStr, [ref]$null, [ref]$null)
                $commandAST = $ast.FindAll({$args[0] -as [System.Management.Automation.Language.CommandAst]},$false)

                for ($x = 1; $x -lt $commandAST.CommandElements.Count; $x++) {
                    $element = $commandAST.CommandElements[$x]

                    # The element is a command parameter (meaning -<ParamName>)
                    # Determine the values for it
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
                                $elementValue = $commandAST.CommandElements[$x+$y]

                                if ($elementValue -is [System.Management.Automation.Language.VariableExpressionAst]) {
                                    # The element 'looks' like a variable reference
                                    # Get the raw text of the value
                                    $paramValues += $elementValue.Extent.Text
                                } else {
                                    if ($elementValue.Value) {
                                       $paramValues += $elementValue.Value
                                    } else {
                                        $paramValues += $elementValue.SafeGetValue()
                                    }
                                }
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
                        if ($element -is [System.Management.Automation.Language.VariableExpressionAst]) {
                            $positionalParams += $element.Extent.Text
                        } else {
                            if ($element.Value) {
                                $positionalParams += $element.Value
                            } else {
                                $positionalParams += $element.SafeGetValue()
                            }
                        }
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
