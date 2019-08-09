---
external help file: PoshBot-help.xml
Module Name: poshbot
online version:
schema: 2.0.0
---

# New-PoshBotScheduledTask

## SYNOPSIS
Creates a new scheduled task to run PoshBot in the background.

## SYNTAX

```
New-PoshBotScheduledTask [[-Name] <String>] [[-Description] <String>] [-Path] <String>
 [-Credential] <PSCredential> [-PassThru] [-Force] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Creates a new scheduled task to run PoshBot in the background.
The scheduled task will always be configured
to run on startup and to not stop after any time period.

## EXAMPLES

### EXAMPLE 1
```
$cred = Get-Credential
```

PS C:\\\> New-PoshBotScheduledTask -Name PoshBot -Path C:\PoshBot\myconfig.psd1 -Credential $cred

Creates a new scheduled task to start PoshBot using the configuration file located at C:\PoshBot\myconfig.psd1
and the specified credential.

### EXAMPLE 2
```
$cred = Get-Credential
```

PC C:\\\> $params = @{
    Name = 'PoshBot'
    Path = 'C:\PoshBot\myconfig.psd1'
    Credential = $cred
    Description = 'Awesome ChatOps bot'
    PassThru = $true
}
PS C:\\\> $task = New-PoshBotScheduledTask @params
PS C:\\\> $task | Start-ScheduledTask

Creates a new scheduled task to start PoshBot using the configuration file located at C:\PoshBot\myconfig.psd1
and the specified credential then starts the task.

## PARAMETERS

### -Name
The name for the scheduled task

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: PoshBot
Accept pipeline input: False
Accept wildcard characters: False
```

### -Description
The description for the scheduled task

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: Start PoshBot
Accept pipeline input: False
Accept wildcard characters: False
```

### -Path
The path to the PoshBot configuration file to load and execute

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential
The credential to run the scheduled task under.

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases:

Required: True
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PassThru
Return the newly created scheduled task object

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

### -Force
Overwrite a previously created scheduled task

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

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### Microsoft.Management.Infrastructure.CimInstance#root/Microsoft/Windows/TaskScheduler/MSFT_ScheduledTask
## NOTES

## RELATED LINKS

[Get-PoshBotConfiguration]()

[New-PoshBotConfiguration]()

[Save-PoshBotConfiguration]()

[Start-PoshBot]()

