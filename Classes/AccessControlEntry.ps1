
# # Used to control access to a plugin command. Identifie who, what, and how.
# class AccessControlEntry {
#     [string]$Id
#     [string]$TrusteeId
#     [AccessRight]$Access

#     AccessControlEntry([string]$TrusteeId, [AccessRight]$Access) {
#         $this.Id = (New-Guid)
#         $this.TrusteeId = $TrusteeId
#         $this.Access = $Access
#     }

#     AccessControlEntry([string]$Id, [string]$TrusteeId, [AccessRight]$Access) {
#         $this.Id = $Id
#         $this.TrusteeId = $TrusteeId
#         $this.Access = $Access
#     }
# }
# function New-PoshBotAce {
#     [cmdletbinding()]
#     param(
#         [string]$Id = (New-Guid),

#         [parameter(Mandatory)]
#         [string]$TrusteeId,

#         [AccessRight]$AccessRight = [AccessRight]::Allow
#     )

#     return [AccessControlEntry]::new($Id, $TrusteeId, $AccessRight)
# }
