
# This class holds the bare minimum information necesary to establish a connection to a chat network.
# Specific implementations MAY extend this class to provide more properties
class ConnectionConfig {

    [string]$Endpoint

    [pscredential]$Credential

    [pscredential]$CredentialApp

    ConnectionConfig() {}

    ConnectionConfig([string]$Endpoint, [pscredential]$Credential) {
        $this.Endpoint = $Endpoint
        $this.Credential = $Credential
    }
}
