# Load Service Bus DLLs
# Windows PowerShell will use full .Net DLLs, PowerShell Core will use .Net core DLLs
try {
    if ($PSVersionTable.PSEdition -eq 'Desktop') {
        $platform = 'windows'
        # [System.Reflection.Assembly]::LoadFrom((Resolve-Path "$PSScriptRoot/lib/$platform/Microsoft.IdentityModel.Clients.ActiveDirectory.dll")) > $null
        # [System.Reflection.Assembly]::LoadFrom((Resolve-Path "$PSScriptRoot/lib/$platform/Microsoft.ServiceBus.dll")) > $null
        # Add-Type -Path "$PSScriptRoot/lib/$platform/netstandard.dll"
        # Add-Type -Path "$PSScriptRoot/lib/$platform/Microsoft.Azure.Amqp.dll"
        # Add-Type -Path "$PSScriptRoot/lib/$platform/Microsoft.Azure.ServiceBus.dll"

        Add-Type -Path "$PSScriptRoot/lib/$platform/netstandard.dll"
        Add-Type -Path "$PSScriptRoot/lib/$platform/System.Diagnostics.DiagnosticSource.dll"
        #Add-Type -Path "$modulePath/lib/$platform/System.IdentityModel.Tokens.Jwt.dll"
        Add-Type -Path "$PSScriptRoot/lib/$platform/Microsoft.Azure.Amqp.dll"
        Add-Type -Path "$PSScriptRoot/lib/$platform/Microsoft.Azure.ServiceBus.dll"
    } else {
        $platform = 'linux'
        Add-Type -Path "$PSScriptRoot/lib/$platform/Microsoft.Azure.Amqp.dll"
        Add-Type -Path "$PSScriptRoot/lib/$platform/Microsoft.Azure.ServiceBus.dll"
    }
} catch {
    throw $_
}
