
# Start-PoshBot

## SYNOPSIS

Starts a new instance of PoshBot interactively or in a job.

## DESCRIPTION

Starts a new instance of PoshBot interactively or in a job.

## PARAMETERS

### InputObject

An existing PoshBot instance to start.

### Configuration

A PoshBot configuration object to use to start the bot instance.

### Path

The path to a PoshBot configuration file.
A new instance of PoshBot will be created from this file.

### AsJob

Run the PoshBot instance in a background job.

### PassThru

Return the PoshBot instance Id that is running as a job.

## EXAMPLES

### EXAMPLE 1

Runs an instance of PoshBot that has already been created interactively in the shell.

```powershell
PS C:\> Start-PoshBot -Bot $bot
```

### EXAMPLE 2

Runs an instance of PoshBot that has already been created interactively in the shell.

```powershell
PS C:\> $bot | Start-PoshBot -Verbose
```

### EXAMPLE 3

Gets a PoshBot configuration from file and starts the bot interactively.

```powershell
PS C:\> $config = Get-PoshBotConfiguration -Path (Join-Path -Path $env:USERPROFILE -ChildPath '.poshbot\MyPoshBot.psd1')
PS C:\> Start-PoshBot -Config $config
```

### EXAMPLE 4

Gets the PoshBot job instance with ID 100.

```powershell
PS C:\> Get-PoshBot -Id 100

Id         : 100
Name       : PoshBot_eab96f2ad147489b9f90e110e02ad805
State      : Running
InstanceId : eab96f2ad147489b9f90e110e02ad805
Config     : BotConfiguration
```

## INPUTS

Bot

## INPUTS

BotConfiguration

## INPUTS

String

## OUTPUTS

PSCustomObject
