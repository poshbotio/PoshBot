
function New-PoshBotTeamsBackend {
    <#
    .SYNOPSIS
        Create a new instance of a Microsoft Teams backend
    .DESCRIPTION
        Create a new instance of a Microsoft Teams backend
    .PARAMETER Configuration
        The hashtable containing backend-specific properties on how to create the instance.
    .EXAMPLE
        PS C:\> $backendConfig = @{
            Name = 'TeamsBackend'
            Credential = [pscredential]::new(
                '<BOT-ID>',
                ('<BOT-PASSWORD>' | ConvertTo-SecureString -AsPlainText -Force)
            )
            ServiceBusNamespace = '<SERVICEBUS-NAMESPACE>'
            QueueName           = '<QUEUE-NAME>'
            AccessKeyName       = '<KEY-NAME>'
            AccessKey           = '<SECRET>' | ConvertTo-SecureString -AsPlainText -Force
        }
        PS C:\> $$backend = New-PoshBotTeamsBackend -Configuration $backendConfig

        Create a Microsoft Teams backend using the specified Bot Framework credentials and Service Bus information
    .INPUTS
        Hashtable
    .OUTPUTS
        TeamsBackend
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope='Function', Target='*')]
    [cmdletbinding()]
    param(
        [parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('BackendConfiguration')]
        [hashtable[]]$Configuration
    )

    begin {
        $requiredProperties = @(
            'BotName', 'TeamId', 'Credential', 'ServiceBusNamespace', 'QueueName', 'AccessKeyName', 'AccessKey'
        )
    }

    process {
        foreach ($item in $Configuration) {

            # Validate required hashtable properties
            if ($missingProperties = $requiredProperties.Where({$item.Keys -notcontains $_})) {
                throw "The following required backend properties are not defined: $($missingProperties -join ', ')"
            }
            Write-Verbose 'Creating new Teams backend instance'

            $connectionConfig = [TeamsConnectionConfig]::new()
            $connectionConfig.BotName             = $item.BotName
            $connectionConfig.TeamId              = $item.TeamId
            $connectionConfig.Credential          = $item.Credential
            $connectionConfig.ServiceBusNamespace = $item.ServiceBusNamespace
            $connectionConfig.QueueName           = $item.QueueName
            $connectionConfig.AccessKeyName       = $item.AccessKeyName
            $connectionConfig.AccessKey           = $item.AccessKey

            $backend = [TeamsBackend]::new($connectionConfig)
            if ($item.Name) {
                $backend.Name = $item.Name
            }
            $backend
        }
    }
}

Export-ModuleMember -Function 'New-PoshBotTeamsBackend'
