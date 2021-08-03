function New-PoshBotTeamsBackend {
    <#
    .SYNOPSIS
        Create a new instance of a Microsoft Teams backend based on Powershell Universal
    .DESCRIPTION
        Create a new instance of a Microsoft Teams backend based on Powershell Universal
    .PARAMETER Configuration
        The hashtable containing backend-specific properties on how to create the instance.
    .EXAMPLE
        PS C:\> 
        TODO provide example
    .INPUTS
        Hashtable
    .OUTPUTS
        PSUTeamsBackend
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope='Function', Target='*')]
    [cmdletbinding()]
    param(
        [parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('BackendConfiguration')]
        [hashtable[]]$Configuration
    )
}