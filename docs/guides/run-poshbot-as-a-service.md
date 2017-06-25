# Run PoshBot as a Service

There are several ways to run PowerShell scripts as a service; We're going to use [nssm](https://nssm.cc/) - it's a bit simpler than some of the [alternatives](https://msdn.microsoft.com/en-us/magazine/mt703436.aspx).

## Ingredients

* Script that will run as a service
* [Latest release of nssm.exe](https://nssm.cc/download)
* PoshBot installed with a configuration to read

## Recipe

* Write the poshbot script that will run as a service.  Here's an example saved as `C:\poshbot\start-poshbot.ps1`:

```powershell
Import-Module PoshBot -force
$pbc = Get-PoshBotConfiguration -Path C:\poshbot\config.psd1

while($True) {
    try {
        $err = $null
        Start-PoshBot -Configuration $pbc -Verbose -ErrorVariable err
        if($err) {
            throw $err
        }
    }
    catch {
        $_ | Format-List -Force | Out-String | Out-File (Join-Path $pbc.LogDirectory Service.Error)
    }
}
```

Adjust the path as needed - we'll use `C:\poshbot\config.psd1` here.

* Download nssm, extract `nssm.exe` (`win64` for typical 64-bit PowerShell)

* Use `nssm.exe` to create a service.  Adjust variables as needed:

```powershell
$nssm = 'C:\nssm.exe'
$ScriptPath = 'C:\poshbot\start-poshbot.ps1'
$ServiceName = 'poshbot'

$ServicePath = 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe'
$ServiceArguments = '-ExecutionPolicy Bypass -NoProfile -File "{0}"' -f $ScriptPath

& $nssm install $ServiceName $ServicePath $ServiceArguments
Start-Sleep -Seconds .5

# check the status... should be stopped
& $nssm status $ServiceName

# start things up!
& $nssm start $ServiceName

# verify it's running
& $nssm status $ServiceName
```

Your PoshBot should be up and running as a service!  You can now start and stop the service like a normal service:

```powershell
Get-Service PoshBot
Stop-Service PoshBot
Start-Service PoshBot
```
