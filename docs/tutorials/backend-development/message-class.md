# Message

This class represents a message that is received from the chat network.
You can optionally create a backend-specific class that derives from this class if additional properties are required by the backend.

## Methods

If you choose to create a derived class of `[Message]`, the following methods need to be implemented.

---

### ToHash()

This method will return a hashtable of all properties of the class.

#### Signature

```powershell
[hashtable] ToHash()
```

#### Parameters:

- None

#### Returns:

**\[hashtable]**
