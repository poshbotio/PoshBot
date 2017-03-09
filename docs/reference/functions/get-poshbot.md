
# Get-PoshBot

## SYNOPSIS

Gets any currently running instances of PoshBot that are running as background jobs.

## DESCRIPTION

PoshBot can be run in the background with PowerShell jobs.
This function returns any currently running PoshBot instances.

## PARAMETERS

### Id

One or more job IDs to retrieve.

## EXAMPLES

### EXAMPLE 1

Get any currently running PoshBot instances.

```powershell
PS C:\> Get-PoshBot

Id         : 5
Name       : PoshBot_3ddfc676406d40fca149019d935f065d
State      : Running
InstanceId : 3ddfc676406d40fca149019d935f065d
Config     : BotConfiguration
```

### EXAMPLE 2

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

System.Int32

## OUTPUTS

PSCustomObject