# Connection

The connection class is used to connect, maintain, and disconnect a session to the chat network.
This will be called from the `Connect()` method of the backend class.
In the Slack and Teams, implementations, this class holds logic to establish a long-lived connection that normally blocks further processing in PowerShell.
Because of this, these backends maintain the connection either in PowerShell jobs or runspaces to keep the main PoshBot instance from pausing.
The `ReceiveMessage()` method in the `Backend` class will then call custom methods of the `[Connection]` class to retrieve the incoming message from the job or runspace.

## Methods

The following methods need to be implemented in the derived class that represents the chat network.

---

### Connect()

This method will establish a connection to the backend chat network.

#### Signature

```powershell
[void]Connect()
```

#### Parameters:

- None

#### Returns:

**\[void]**

---

### Disconnect()

This method will disconnect the connection to the backend chat network.

#### Signature

```powershell
[void]Disconnect()
```

#### Parameters:

- None

#### Returns:

**\[void]**
