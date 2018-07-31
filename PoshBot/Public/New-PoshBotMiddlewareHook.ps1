
function New-PoshBotMiddlewareHook {
    <#
    .SYNOPSIS
        Creates a PoshBot middleware hook object.
    .DESCRIPTION
        PoshBot can execute custom scripts during various stages of the command processing lifecycle. These scripts
        are defined using New-PoshBotMiddlewareHook and added to the bot configuration object under the MiddlewareConfiguration section.
        Hooks are added to the PreReceive, PostReceive, PreExecute, PostExecute, PreResponse, and PostResponse properties.
        Middleware gets executed in the order in which it is added under each property.
    .PARAMETER Name
        The name of the middleware hook. Must be unique in each middleware lifecycle stage.
    .PARAMETER Path
        The file path the the PowerShell script to execute as a middleware hook.
    .EXAMPLE
        PS C:\> $userDropHook = New-PoshBotMiddlewareHook -Name 'dropuser' -Path 'c:/poshbot/middleware/dropuser.ps1'
        PS C:\> $config.MiddlewareConfiguration.Add($userDropHook, 'PreReceive')

        Creates a middleware hook called 'dropuser' and adds it to the 'PreReceive' middleware lifecycle stage.
    .OUTPUTS
        MiddlewareHook
    #>
    [cmdletbinding()]
    param(
        [parameter(mandatory)]
        [string]$Name,

        [parameter(mandatory)]
        [ValidateScript({
            if (-not (Test-Path -Path $_)) {
                throw 'Invalid script path'
            } else {
                $true
            }
        })]
        [string]$Path
    )

    [MiddlewareHook]::new($Name, $Path)
}

Export-ModuleMember -Function 'New-PoshBotMiddlewareHook'
