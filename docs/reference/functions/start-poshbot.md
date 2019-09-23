---
external help file: PoshBot-help.xml
Module Name: poshbot
online version:
schema: 2.0.0
---

# Start-PoshBot

## SYNOPSIS
Starts a new instance of PoshBot interactively or in a job.

## SYNTAX

### bot (Default)
```
Start-PoshBot -InputObject <Bot> [-AsJob] [-PassThru] [<CommonParameters>]
```

### config
```
Start-PoshBot -Configuration <BotConfiguration> [-AsJob] [-PassThru] [<CommonParameters>]
```

### path
```
Start-PoshBot -Path <String> [-AsJob] [-PassThru] [<CommonParameters>]
```

## DESCRIPTION
Starts a new instance of PoshBot interactively or in a job.

## EXAMPLES

### EXAMPLE 1
```
Start-PoshBot -Bot $bot
```

Runs an instance of PoshBot that has already been created interactively in the shell.

### EXAMPLE 2
```
$bot | Start-PoshBot -Verbose
```

Runs an instance of PoshBot that has already been created interactively in the shell.

### EXAMPLE 3
```
$config = Get-PoshBotConfiguration -Path (Join-Path -Path $env:USERPROFILE -ChildPath '.poshbot\MyPoshBot.psd1')
```

PS C:\\\> Start-PoshBot -Config $config

Gets a PoshBot configuration from file and starts the bot interactively.

### EXAMPLE 4
```
Get-PoshBot -Id 100
```

Id         : 100
Name       : PoshBot_eab96f2ad147489b9f90e110e02ad805
State      : Running
InstanceId : eab96f2ad147489b9f90e110e02ad805
Config     : BotConfiguration

Gets the PoshBot job instance with ID 100.

## PARAMETERS

### -InputObject
An existing PoshBot instance to start.

```yaml
Type: Bot
Parameter Sets: bot
Aliases: Bot

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Configuration
A PoshBot configuration object to use to start the bot instance.

```yaml
Type: BotConfiguration
Parameter Sets: config
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Path
The path to a PoshBot configuration file.
A new instance of PoshBot will be created from this file.

```yaml
Type: String
Parameter Sets: path
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AsJob
Run the PoshBot instance in a background job.

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

### -PassThru
Return the PoshBot instance Id that is running as a job.

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

### Bot
### BotConfiguration
### String
## OUTPUTS

### PSCustomObject
## NOTES

## RELATED LINKS

[Start-PoshBot]()

[Stop-PoshBot]()

