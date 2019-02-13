# Backend

This class represents the backend chat network and contains the primary methods that PoshBot will call to send and receive messages.

## Methods

The following methods need to be implemented in the derived class that represents the chat network.

---

### SendMessage()

This method will be called by PoshBot to send a message back to the chat network.

#### Signature

```powershell
[void] SendMessage([Response]$Response)
```

#### Parameters:

- **[Response]** $Response

  The response that will be send back to the chat network.

#### Returns:

**\[void]**

---

### AddReaction()

Attach a reaction to the message in the chat network that called a command.
This is typically used to tag the message as being processed by PoshBot, and to indicate the commands' success or failure.
If a backend does not support the concept of reactions on messages, this method must still be implemented but can safely do nothing.

#### Signature

```powershell
[void] AddReaction([Message]$Message, [ReactionType]$Type, [string]$Reaction)
```

#### Parameters:

- **[Message]** $Message

  The message that the reaction will be added to.

- **[ReactionType]** $Type

  The type of pre-defined reaction to attach.

- **[string]** $Reaction

  A custom reaction type to attach.

#### Returns:

**\[void]**

---

### RemoveReaction()

This method will remove a given reaction from a message.
As an example, this method could be used to remove an "in process" reaction that was added to indicate that PoshBot received a command and is currently executing it.

#### Signature

```powershell
[void] RemoveReaction([Message]$Message, [ReactionType]$Type, [string]$Reaction)
```

#### Parameters:

- **[Message]** $Message

  The message that the reaction will be removed from.

- **[ReactionType]** $Type

  The type of pre-defined reaction to remove.

- **[string]** $Reaction

  A custom reaction type to remove.

#### Returns:

**\[void]**

---

### ReceiveMessage()

This method will be called frequently by PoshBot to receive any messages from the chat network.
Because of PoshBots' design, this method will be called many times a second.
It is expected that this method return quickly so as to not introduce undue latency to PoshBots' processing.
Techniques like separate PowerShell jobs or runspaces can be used to contain the actual logic of receiving messages from the chat network if that logic is long running or blocking. This method can then be used to retrieve messages from those constructs quickly.

#### Signature

```powershell
[Message[]]ReceiveMessage()
```

#### Parameters:

- **[Message]** $Message

  The message that the reaction will be removed from.

- **[ReactionType]** $Type

  The type of pre-defined reaction to remove.

- **[string]** $Reaction

  A custom reaction type to remove.

#### Returns:

**\[Message[]]**

An array of message objects received from the chat network.
If the chat network has no messages to return, this method must return an empty array.

---

### Ping()

This method can be used to send some typo of keep alive message back to the chat network to keep a connection open.
If that concept does not apply to the chat network, this method does not need to be implemented.

#### Signature

```powershell
[void] Ping()
```

#### Parameters:

- None

#### Returns:

**\[void]**

---

### [Person]GetUser([string]$UserId)

This method must return an instance of a `[Person]` or a class derived from `[Person]` when given an id.

#### Signature

```powershell
[Person] GetUser([string]$UserId)
```

#### Parameters:

- **[string]** $UserId

  The id of the user to return.

#### Returns:

**\[Person]**

---

### Connect()

This method will be called to establish a new connection to the chat network.

#### Signature

```powershell
[void] Connect()
```

#### Parameters:

- None

#### Returns:

**\[void]**

---

### Disconnect()

This method will be called to terminate the connection to the chat network.

#### Signature

```powershell
[void] Disconnect()
```

#### Parameters:

- None

#### Returns:

**\[void]**

---

### LoadUsers()

This method will contain the logic to populate the list of users on the chat network.

#### Signature

```powershell
[void] LoadUsers()
```

#### Parameters:

- None

#### Returns:

**\[void]**

---

### LoadRooms()

This method will contain the logic to populate the list of rooms or channels on the chat network.

#### Signature

```powershell
[void] LoadUsers()
```

#### Parameters:

- None

#### Returns:

**\[void]**

---

### GetBotIdentity()

This method will contain the logic to return the bots' identifier on the chat network.
This is used for such things as determining if incoming messages from the chat network originated from the bot user.
These types of messages should usually be ignored to avoid feedback loops.

#### Signature

```powershell
[string] GetBotIdentity()
```

#### Parameters:

- None

#### Returns:

**\[string]**

---

### UsernameToUserId()

This method will return the id of a user given their unique username on the chat network.

#### Signature

```powershell
[string] UsernameToUserId([string]$Username)
```

#### Parameters:

- **[string]** $Username

  The username to resolve to an id.

#### Returns:

**\[string]**

---

### UserIdToUsername()

This method will return the unique username of a user when given their id.

#### Signature

```powershell
[string] UserIdToUsername([string]$UserId)
```

#### Parameters:

- **[string]** $UserId

  The id to resolve to a username.

#### Returns:

**\[string]**

---

### GetUserInfo()

This method will return all the information for a user when given their id.
This information is made available to commands when they are executed.

#### Signature

```powershell
[hashtable] GetUserInfo([string]$UserId)
```

#### Parameters:

- **[string]** $UserId

  The id of the user to retrieve.

#### Returns:

**\[hashtable]**

---

### ChannelIdToName()

This method will return the channel or room name for a given id.

#### Signature

```powershell
[string] ChannelIdToName([string]$ChannelId)
```

#### Parameters:

- **[string]** $ChannelId

  The id of the channel to resolve to a name.

#### Returns:

**\[string]**
