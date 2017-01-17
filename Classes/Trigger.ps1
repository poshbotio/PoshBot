
class Trigger {
    [TriggerType]$Type
    [string]$Trigger

    Trigger([TriggerType]$Type, [string]$Trigger) {
        $this.Type = $Type
        $this.Trigger = $Trigger
    }
}
