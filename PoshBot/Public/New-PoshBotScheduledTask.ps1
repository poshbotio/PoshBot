
function New-PoshBotScheduledTask {
    <#
    .SYNOPSIS
        Creates a new scheduled task to run PoshBot in the background.
    .DESCRIPTION
        Creates a new scheduled task to run PoshBot in the background. The scheduled task will always be configured
        to run on startup and to not stop after any time period.
    .PARAMETER Name
        The name for the scheduled task
    .PARAMETER Description
        The description for the scheduled task
    .PARAMETER Path
        The path to the PoshBot configuration file to load and execute
    .PARAMETER Credential
        The credential to run the scheduled task under.
    .PARAMETER PassThru
        Return the newly created scheduled task object
    .PARAMETER Force
        Overwrite a previously created scheduled task
    .EXAMPLE
        PS C:\> $cred = Get-Credential
        PS C:\> New-PoshBotScheduledTask -Name PoshBot -Path C:\PoshBot\myconfig.psd1 -Credential $cred

        Creates a new scheduled task to start PoshBot using the configuration file located at C:\PoshBot\myconfig.psd1
        and the specified credential.
    .EXAMPLE
        PS C:\> $cred = Get-Credential
        PC C:\> $params = @{
            Name = 'PoshBot'
            Path = 'C:\PoshBot\myconfig.psd1'
            Credential = $cred
            Description = 'Awesome ChatOps bot'
            PassThru = $true
        }
        PS C:\> $task = New-PoshBotScheduledTask @params
        PS C:\> $task | Start-ScheduledTask

        Creates a new scheduled task to start PoshBot using the configuration file located at C:\PoshBot\myconfig.psd1
        and the specified credential then starts the task.
    .OUTPUTS
        Microsoft.Management.Infrastructure.CimInstance#root/Microsoft/Windows/TaskScheduler/MSFT_ScheduledTask
    .LINK
        Get-PoshBotConfiguration
    .LINK
        New-PoshBotConfiguration
    .LINK
        Save-PoshBotConfiguration
    .LINK
        Start-PoshBot
    #>
    [cmdletbinding(SupportsShouldProcess)]
    param(
        [string]$Name = 'PoshBot',

        [string]$Description = 'Start PoshBot',

        [parameter(Mandatory)]
        [ValidateScript({
            if (Test-Path -Path $_) {
                if ( (Get-Item -Path $_).Extension -eq '.psd1') {
                    $true
                } else {
                    Throw 'Path must be to a valid .psd1 file'
                }
            } else {
                Throw 'Path is not valid'
            }
        })]
        [string]$Path,

        [parameter(Mandatory)]
        [pscredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential,

        [switch]$PassThru,

        [switch]$Force
    )

    if ($Force -or (-not (Get-ScheduledTask -TaskName $Name -ErrorAction SilentlyContinue))) {
        if ($PSCmdlet.ShouldProcess($Name, 'Created PoshBot scheduled task')) {

            $taskParams = @{
                Description = $Description
            }

            # Determine path to scheduled task script
            # Not adding '..\' to -ChildPath parameter because during module build
            # this script will get merged into PoshBot.psm1 and \Task folder will be
            # a direct child of $PSScriptRoot
            $startScript = Resolve-Path -LiteralPath (Join-Path -Path $PSScriptRoot -ChildPath 'Task\StartPoshBot.ps1')

            # Scheduled task action
            $arg = "& '$startScript' -Path '$Path'"
            $actionParams = @{
                Execute = "$($env:SystemDrive)\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
                Argument = '-ExecutionPolicy Bypass -NonInteractive -Command "' + $arg + '"'
                WorkingDirectory = $PSScriptRoot
            }
            $taskParams.Action = New-ScheduledTaskAction @actionParams

            # Scheduled task at logon trigger
            $taskParams.Trigger = New-ScheduledTaskTrigger -AtStartup

            # Scheduled task settings
            $settingsParams = @{
                AllowStartIfOnBatteries = $true
                DontStopIfGoingOnBatteries = $true
                ExecutionTimeLimit = 0
                RestartCount = 999
                RestartInterval = (New-TimeSpan -Minutes 1)
            }
            $taskParams.Settings = New-ScheduledTaskSettingsSet @settingsParams

            # Create / register the task
            $registerParams = @{
                TaskName = $Name
                Force = $true
            }
            # Scheduled task principal
            $registerParams.User = $Credential.UserName
            $registerParams.Password = $Credential.GetNetworkCredential().Password
            $task = New-ScheduledTask @taskParams
            $newTask = Register-ScheduledTask -InputObject $task @registerParams
            if ($PassThru) {
                $newTask
            }
        }
    } else {
        Write-Error -Message "Existing task named [$Name] found. To overwrite, use the -Force"
    }
}

Export-ModuleMember -Function 'New-PoshBotScheduledTask'
