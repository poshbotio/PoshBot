
# Stop-PoshBot

## SYNOPSIS

Stop a currently running PoshBot instance that is running as a background job.

## DESCRIPTION

PoshBot can be run in the background with PowerShell jobs.
This function stops a currently running PoshBot instance.

## PARAMETERS

### Id

The job Id of the bot to stop.

## EXAMPLES

### EXAMPLE 1

Stop the bot instance with Id 101.

```powershell
PS C:\> Stop-PoshBot -Id 101
```

### EXAMPLE 2

Gets all running PoshBot instances and stops them.

```powershell
PS C:\> Get-PoshBot | Stop-PoshBot
```

## INPUTS
System.Int32
