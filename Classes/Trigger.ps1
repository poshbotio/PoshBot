
class Trigger {
    [TriggerType]$Type
    [string]$Trigger
    [MessageType]$MessageType = [MessageType]::Message
    [MessageSubType]$MessageSubtype = [Messagesubtype]::None

    Trigger([TriggerType]$Type, [string]$Trigger) {
        $this.Type = $Type
        $this.Trigger = $Trigger
    }
}
