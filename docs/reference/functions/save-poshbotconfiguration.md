
# Save-PoshBotConfiguration

## SYNOPSIS

Saves a PoshBot configuration object to the filesystem in the form of a PowerShell data (.psd1) file.

## DESCRIPTION

PoshBot configurations can be stored on the filesytem in PowerShell data (.psd1) files.
This function will save a previously created configuration object to the filesystem.

## PARAMETERS

### InputObject

    The bot configuration object to save to the filesystem.

### Path

The path to a PowerShell data (.psd1) file to save the configuration to.

### Force

Overwrites an existing configuration file.

### PassThru

Returns the configuration file path.

## EXAMPLES

### EXAMPLE 1

Saves the PoshBot configuration. If now -Path is specified, the configuration will be saved to $env:USERPROFILE\.poshbot\PoshBot.psd1.

```powershell
PS C:\> Save-PoshBotConfiguration -InputObject $botConfig
```

### EXAMPLE 2

Saves the PoshBot configuration to [c:\mybot\mybot.psd1].

```powershell
PS C:\> $botConfig | Save-PoshBotConfig -Path c:\mybot\mybot.psd1
```

### EXAMPLE 3

Saves the PoshBot configuration to [c:\mybot\mybot.psd1] and Overwrites existing file. The new file will be returned.

```powershell
PS C:\> $configFile = $botConfig | Save-PoshBotConfig -Path c:\mybot\mybot.psd1 -Force -PassThru
```

## INPUTS

BotConfiguration

## OUTPUTS

System.IO.FileInfo
