
# https://gallery.technet.microsoft.com/Generic-PowerShell-string-e9ccfe73
function Get-StringToken
{
    <#
    .Synopsis
       Converts a string into individual tokens.
    .DESCRIPTION
       Converts a string into tokens, with customizable behavior around delimiters and handling of qualified (quoted) strings.
    .PARAMETER String
       The string to be parsed.  Can be passed in as an array of strings (with each element of the array treated as a separate line), or as a single string containing embedded `r and/or `n characters.
    .PARAMETER Delimiter
       The delimiters separating each token.  May be passed as a single string or an array of string; either way, every character in the strings is treated as a delimiter.  The default delimiters are spaces and tabs.
    .PARAMETER Qualifier
       The characters that can be used to qualify (quote) tokens that contain embedded delimiters.  As with delimiters, may be specified either as an array of strings, or as a single string that contains all legal qualifier characters.  Default is double quotation marks.
    .PARAMETER Escape
       The characters that can be used to escape an embedded qualifier inside a qualified token.  You do not need to specify the qualifiers themselves (ie, to allow two consecutive qualifiers to embed one in the token); that behavior is handled separately by the -NoDoubleQualifiers switch.  Default is no escape characters.  Note: An escape character that is NOT followed by the active qualifier is not treated as anything special; the escape character will be included in the token.
    .PARAMETER LineDelimiter
       If -Span is specified, and if the opening and closing qualifers of a token are found in different elements of the -String array, the string specified by -LineDelimiter will be injected into the token.  Defaults to "`r`n"
    .PARAMETER NoDoubleQualifier
       By default, the function treats two consecutive qualifiers as one embedded qualifier character in a token.  (ie:  "a ""token"" string").  Specifying -NoDoubleQualifier disables this behavior, causing only the -Escape characters to be allowed for embedding qualifiers in a token.
    .PARAMETER IgnoreConsecutiveDelimiters
       By default, if the script finds consecutive delimiters, it will output empty strings as tokens.  Specifying -IgnoreConsecutiveDelimiters treat consecutive delimiters as one (effectively only outputting non-empty tokens, unless the empty string is qualified / quoted).
    .PARAMETER Span
       Passing the Span switch allows qualified tokens to contain embedded end-of-line characters.
    .PARAMETER GroupLines
       Passing the GroupLines switch causes the function to return an object for each line of input.  If the Span switch is also used, multiple lines of text from the input may be merged into one output object.
       Each output object will have a Tokens collection.
    .EXAMPLE
       Get-StringToken -String @("Line 1","Line`t 2",'"Line 3"')

       Tokenizes an array of strings using the function's default behavior (spaces and tabs as delimiters, double quotation marks as a qualifier, consecutive delimiters produces an empty token).  In this example, six tokens will be output.  The single quotes in the example output are not part of the tokens:

       'Line'
       '1'
       'Line'
       ''
       '2'
       'Line 3'
    .EXAMPLE
       $strings | Get-StringToken -Delimiter ',' -Qualifier '"' -Span

       Pipes a string or string collection to Get-StringToken.  Text is treated as comma-delimeted, with double quotation qualifiers, and qualified tokens may span multiple lines.  In effect, CSV file format.
    .EXAMPLE
       $strings | Get-StringToken -Qualifier '"' -IgnoreConsecutiveDelimeters -Escape '\' -NoDoubleQualifier

       Pipes a string or string collection to Get-StringToken.  Uses the default delimiters of tab and space.  Double quotes are the qualifier, and embedded quotes must be escaped with a backslash; placing two consecutive double quotes is disabled by the -NoDoubleQualifier argument.  Consecutive delimiters are ignored.
    .INPUTS
       [System.String] - The string to be parsed.
    .OUTPUTS
       [System.String] - One string for each token.
       [PSObject] - If the GroupLines switch is used, the function outputs custom objects with a Tokens property.  The Tokens property is an array of strings.
    .NOTES
       Author:  Dave Wyatt
       Email :  dlwyatt115@gmail.com
       Date  :  07-Dec-2013
    #>

    #requires -Version 2

    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [System.String[]]
        $String,

        [ValidateNotNull()]
        [System.String[]]
        $Delimiter = @("`t",' '),

        [ValidateNotNull()]
        [System.String[]]
        $Qualifier = @('"', "'"),

        [ValidateNotNull()]
        [System.String[]]
        $Escape = @(),

        [ValidateNotNull()]
        [System.String]
        $LineDelimiter = "`r`n",

        [Switch]
        $NoDoubleQualifier,

        [Switch]
        $Span,

        [Switch]
        $GroupLines,

        [Switch]
        $IgnoreConsecutiveDelimiters
    )

    begin
    {
        $currentToken = New-Object System.Text.StringBuilder
        $currentQualifer = $null

        $delimiters = @{}
        foreach ($item in $Delimiter)
        {
            foreach ($character in $item.GetEnumerator())
            {
                $delimiters[$character] = $true
            }
        }

        $qualifiers = @{}
        foreach ($item in $Qualifier)
        {
            foreach ($character in $item.GetEnumerator())
            {
                $qualifiers[$character] = $true
            }
        }

        $escapeChars = @{}
        foreach ($item in $Escape)
        {
            foreach ($character in $item.GetEnumerator())
            {
                $escapeChars[$character] = $true
            }
        }

        if ($NoDoubleQualifier)
        {
            $doubleQualifierIsEscape = $false
        }
        else
        {
            $doubleQualifierIsEscape = $true
        }

        $lineGroup = New-Object System.Collections.ArrayList

    } # end begin block

    process
    {
        foreach ($str in $String)
        {
            # If the last $str value was in the middle of building a token when the end of the string was reached,
            # handle it before parsing the current $str.
            if ($currentToken.Length -gt 0)
            {
                if ($currentQualifer -ne $null -and $Span)
                {
                    $null = $currentToken.Append($LineDelimiter)
                }

                else
                {
                    if ($GroupLines)
                    {
                        $null = $lineGroup.Add($currentToken.ToString())
                    }
                    else
                    {
                        Write-Output $currentToken.ToString()
                    }

                    $currentToken.Length = 0
                    $currentQualifer = $null
                }
            }

            if ($GroupLines -and $lineGroup.Count -gt 0)
            {
                Write-Output (New-Object psobject -Property @{
                    Tokens = $lineGroup.ToArray()
                })

                $lineGroup.Clear()
            }

            for ($i = 0; $i -lt $str.Length; $i++)
            {
                $currentChar = $str.Chars($i)

                if ($currentQualifer)
                {
                    # Line breaks in qualified token.
                    if (($currentChar -eq "`n" -or $currentChar -eq "`r") -and -not $Span)
                    {
                        if ($currentToken.Length -gt 0 -or -not $IgnoreConsecutiveDelimiters)
                        {
                            if ($GroupLines)
                            {
                                $null = $lineGroup.Add($currentToken.ToString())
                            }
                            else
                            {
                                Write-Output $currentToken.ToString()
                            }

                            $currentToken.Length = 0
                            $currentQualifer = $null
                        }

                        if ($GroupLines -and $lineGroup.Count -gt 0)
                        {
                            Write-Output (New-Object psobject -Property @{
                                Tokens = $lineGroup.ToArray()
                            })

                            $lineGroup.Clear()
                        }

                        # We're not including the line breaks in the token, so eat the rest of the consecutive line break characters.
                        while ($i+1 -lt $str.Length -and ($str.Chars($i+1) -eq "`r" -or $str.Chars($i+1) -eq "`n"))
                        {
                            $i++
                        }
                    }

                    # Embedded, escaped qualifiers
                    elseif (($escapeChars.ContainsKey($currentChar) -or ($currentChar -eq $currentQualifer -and $doubleQualifierIsEscape)) -and
                             $i+1 -lt $str.Length -and $str.Chars($i+1) -eq $currentQualifer)
                    {
                        $null = $currentToken.Append($currentQualifer)
                        $i++
                    }

                    # Closing qualifier
                    elseif ($currentChar -eq $currentQualifer)
                    {
                        if ($GroupLines)
                        {
                            $null = $lineGroup.Add($currentToken.ToString())
                        }
                        else
                        {
                            Write-Output $currentToken.ToString()
                        }

                        $currentToken.Length = 0
                        $currentQualifer = $null

                        # Eat any non-delimiter, non-EOL text after the closing qualifier, plus the next delimiter.  Sets the loop up
                        # to begin processing the next token (or next consecutive delimiter) next time through.  End-of-line characters
                        # are left alone, because eating them can interfere with the GroupLines switch behavior.
                        while ($i+1 -lt $str.Length -and $str.Chars($i+1) -ne "`r" -and $str.Chars($i+1) -ne "`n" -and -not $delimiters.ContainsKey($str.Chars($i+1)))
                        {
                            $i++
                        }

                        if ($i+1 -lt $str.Length -and $delimiters.ContainsKey($str.Chars($i+1)))
                        {
                            $i++
                        }
                    }

                    # Token content
                    else
                    {
                        $null = $currentToken.Append($currentChar)
                    }

                } # end if ($currentQualifier)

                else
                {
                    Write-Debug ([int]$currentChar)

                    # Opening qualifier
                    if ($currentToken.ToString() -match '^\s*$' -and $qualifiers.ContainsKey($currentChar))
                    {
                        $currentQualifer = $currentChar
                        $currentToken.Length = 0
                    }

                    # Delimiter
                    elseif ($delimiters.ContainsKey($currentChar))
                    {
                        if ($currentToken.Length -gt 0 -or -not $IgnoreConsecutiveDelimiters)
                        {
                            if ($GroupLines)
                            {
                                $null = $lineGroup.Add($currentToken.ToString())
                            }
                            else
                            {
                                Write-Output $currentToken.ToString()
                            }

                            $currentToken.Length = 0
                            $currentQualifer = $null
                        }
                    }

                    # Line breaks (not treated quite the same as delimiters)
                    elseif ($currentChar -eq "`n" -or $currentChar -eq "`r")
                    {
                        if ($currentToken.Length -gt 0)
                        {
                            if ($GroupLines)
                            {
                                $null = $lineGroup.Add($currentToken.ToString())
                            }
                            else
                            {
                                Write-Output $currentToken.ToString()
                            }

                            $currentToken.Length = 0
                            $currentQualifer = $null
                        }

                        if ($GroupLines -and $lineGroup.Count -gt 0)
                        {
                            Write-Output (New-Object psobject -Property @{
                                Tokens = $lineGroup.ToArray()
                            })

                            $lineGroup.Clear()
                        }
                    }

                    # Token content
                    else
                    {
                        $null = $currentToken.Append($currentChar)
                    }

                } # -not $currentQualifier

            } # end for $i = 0 to $str.Length

        } # end foreach $str in $String

    } # end process block

    end
    {
        if ($currentToken.Length -gt 0)
        {
            if ($GroupLines)
            {
                $null = $lineGroup.Add($currentToken.ToString())
            }
            else
            {
                Write-Output $currentToken.ToString()
            }
        }

        if ($GroupLines -and $lineGroup.Count -gt 0)
        {
            Write-Output (New-Object psobject -Property @{
                Tokens = $lineGroup.ToArray()
            })
        }
    }

}
