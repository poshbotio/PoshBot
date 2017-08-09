
# This class represents the connection to a backend Chat network

class Connection : BaseLogger {
    [ConnectionConfig]$Config
    [ConnectionStatus]$Status = [ConnectionStatus]::Disconnected

    [void]Connect() {}

    [void]Disconnect() {}
}
