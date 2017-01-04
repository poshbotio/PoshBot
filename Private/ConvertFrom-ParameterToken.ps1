function ConvertFrom-ParameterToken {
    [cmdletbinding()]
    param(
        [parameter(Mandatory = 'true')]
        [string[]]$Tokens
    )

    begin {
        $r = [pscustomobject]@{
            Tokens = $Tokens
            NamedParameters = @{}
            PositionalParameters = @()
        }

    }

    end {
        # Don't start from the first token (0), that is the command name
        for ($x=1; $x -lt $Tokens.Count; $x++) {
            $p = $Tokens[$x]

            if ($p -match '^--') {

                $paramName = $p.TrimStart('--')

                # This is a named parameter (or a switch)
                # If named parameter, the next parameter should not
                # begin with "--". If it does then this parameter should be
                # considered a switch
                if (($tokens[$x+1] -match '^--') -or $x -eq $Tokens.Count-1) {
                    # This is a switch parameter
                    if (-not $namedParameters.ContainsKey($p)) {
                        $r.NamedParameters.Add($paramName, $true)
                    }
                } else {
                    # Assume the item following this parameter is the value
                    # for the parameter
                    if ($tokens[$x+1]) {
                        $r.NamedParameters.Add($paramName, $Tokens[$x+1])
                    }
                }
            } else {
                # Positional parameters are items where
                # the previous item ISN'T and parameter name (--param)

                if (($Tokens[$x-1] -notmatch '^--') -and ($x-1 -ge 0)) {
                    $r.PositionalParameters += $p
                }
            }
        }
        $r
    }
}
