
function New-PoshBotTrigger {
    [cmdletbinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [TriggerType]$Type = [System.Enum]::GetValues([TrggerType]),

        [parameter(Mandatory)]
        [string]$Trigger
    )

    return [Trigger]::new($Type, $Trigger)
}
