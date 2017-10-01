
class CommandAuthorizationResult {
    [bool]$Authorized
    [string]$Message

    CommandAuthorizationResult() {
        $this.Authorized = $true
    }

    CommandAuthorizationResult([bool]$Authorized) {
        $this.Authorized = $Authorized
    }

    CommandAuthorizationResult([bool]$Authorized, [string]$Message) {
        $this.Authorized = $Authorized
        $this.Message = $Message
    }
}
