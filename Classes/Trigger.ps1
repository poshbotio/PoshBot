
class Trigger {
    [TriggerType]$Type
    [string]$Trigger

    Trigger([TriggerType]$Type, [string]$Trigger) {
        $this.Type = $Type
        $this.Trigger = $Trigger
    }
}

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
