
function New-PoshBotMiddlewareHook {
    [cmdletbinding()]
    param(
        [parameter(mandatory)]
        [string]$Name,

        [parameter(mandatory)]
        [scriptblock]$ScriptBlock
    )

    [MiddlewareHook]::new($Name, $ScriptBlock)
}

Export-ModuleMember -Function 'New-PoshBotMiddlewareHook'
