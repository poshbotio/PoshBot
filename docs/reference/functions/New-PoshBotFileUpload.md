---
external help file: PoshBot-help.xml
Module Name: poshbot
online version:
schema: 2.0.0
---

# New-PoshBotFileUpload

## SYNOPSIS
Tells PoshBot to upload a file to the chat network.

## SYNTAX

### Path (Default)
```
New-PoshBotFileUpload [-Path] <String[]> [-Title <String>] [-DM] [-KeepFile] [<CommonParameters>]
```

### LiteralPath
```
New-PoshBotFileUpload [-LiteralPath] <String[]> [-Title <String>] [-DM] [-KeepFile] [<CommonParameters>]
```

### Content
```
New-PoshBotFileUpload -Content <String> [-FileType <String>] [-FileName <String>] [-Title <String>] [-DM]
 [-KeepFile] [<CommonParameters>]
```

## DESCRIPTION
Returns a custom object back to PoshBot telling it to upload the given file to the chat network.
The custom object
can also tell PoshBot to redirect the file upload to a DM channel with the calling user.
This could be useful if
the contents the bot command returns are sensitive and should not be visible to all users in the channel.

## EXAMPLES

### EXAMPLE 1
```
function Do-Stuff {
```

\[cmdletbinding()\]
    param()

    $myObj = \[pscustomobject\]@{
        value1 = 'foo'
        value2 = 'bar'
    }

    $csv = Join-Path -Path $env:TEMP -ChildPath "$((New-Guid).ToString()).csv"
    $myObj | Export-Csv -Path $csv -NoTypeInformation

    New-PoshBotFileUpload -Path $csv
}

Export a CSV file and tell PoshBot to upload the file back to the channel that initiated this command.

### EXAMPLE 2
```
function Get-SecretPlan {
```

\[cmdletbinding()\]
    param()

    $myObj = \[pscustomobject\]@{
        Title = 'Secret moon base'
        Description = 'Plans for secret base on the dark side of the moon'
    }

    $csv = Join-Path -Path $env:TEMP -ChildPath "$((New-Guid).ToString()).csv"
    $myObj | Export-Csv -Path $csv -NoTypeInformation

    New-PoshBotFileUpload -Path $csv -Title 'YourEyesOnly.csv' -DM
}

Export a CSV file and tell PoshBot to upload the file back to a DM channel with the calling user.

### EXAMPLE 3
```
function Do-Stuff {
```

\[cmdletbinding()\]
    param()

    $myObj = \[pscustomobject\]@{
        value1 = 'foo'
        value2 = 'bar'
    }

    $csv = Join-Path -Path $env:TEMP -ChildPath "$((New-Guid).ToString()).csv"
    $myObj | Export-Csv -Path $csv -NoTypeInformation

    New-PoshBotFileUpload -Path $csv -KeepFile
}

Export a CSV file and tell PoshBot to upload the file back to the channel that initiated this command.
Keep the file after uploading it.

## PARAMETERS

### -Path
The path(s) to one or more files to upload.
Wildcards are permitted.

```yaml
Type: String[]
Parameter Sets: Path
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: True
```

### -LiteralPath
Specifies the path(s) to the current location of the file(s).
Unlike the Path parameter, the value of LiteralPath is used exactly as it is typed.
No characters are interpreted as wildcards.
If the path includes escape characters, enclose it in single quotation marks.
Single quotation
marks tell PowerShell not to interpret any characters as escape sequences.

```yaml
Type: String[]
Parameter Sets: LiteralPath
Aliases: PSPath

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Content
The content of the file to send.

```yaml
Type: String
Parameter Sets: Content
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FileType
If specified, override the file type determined by the filename.

```yaml
Type: String
Parameter Sets: Content
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FileName
The name to call the uploaded file

```yaml
Type: String
Parameter Sets: Content
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Title
The title for the uploaded file.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: [string]::Empty
Accept pipeline input: False
Accept wildcard characters: False
```

### -DM
Tell PoshBot to redirect the file upload to a DM channel.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -KeepFile
If specified, keep the source file after calling Send-SlackFile.
The source file is deleted without this

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### String
## OUTPUTS

### PSCustomObject
## NOTES

## RELATED LINKS

[New-PoshBotCardResponse]()

[New-PoshBotTextResponse]()

