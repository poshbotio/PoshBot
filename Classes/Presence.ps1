
# class Presence {
#     [Identifier]$Identifier
#     [string]$Status
#     [string]$Message

#     Presence(
#         [Identifier]$Identifier,
#         [string]$Status,
#         [string]$Message
#     ) {
#         $this.Identifier = $Identifier
#         $this.Status = $Status
#         $this.Message = $Message
#     }

#     [string]ToString() {
#         $resp = "Identifier: [$($this.Identifier.Id)] Status: [$($this.Status)] Message: [$($this.Message)]"
#         return $resp
#     }
# }

