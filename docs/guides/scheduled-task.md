
# Running PoshBot as a Scheduled Task

Running PoshBot in the foreground is great for testing use cases.
Production is a different story.
You'll want PoshBot running in the background and ensure it starts up after a restart.
The simplest way to do that is to create a scheduled task that will run on startup.

The included function **New-PoshBotScheduledTask** will do just that.
Provided you have a PoshBot configuration file (.psd1) already built, the code below will get a PowerShell credential object, create the scheduled task, and start it.

#### StartPoshBot.ps1

```powershell
$cred = Get-Credential
$params = @{
    Name = 'PoshBot'
    Path = 'C:\PoshBot\myconfig.psd1'
    Credential = $cred
    Description = 'Awesome ChatOps bot'
    PassThru = $true
}
$task = New-PoshBotScheduledTask @params
$task | Start-ScheduledTask
```
