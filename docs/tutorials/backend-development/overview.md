
# Backend Development

Backends in PoshBot contain the necessary logic to send and receive messages from a particular chat network like Slack or Microsoft Teams.
PoshBot is written to be agnostic to the particular backend you choose to use.
Specific backend implementations must conform to certain standards that PoshBot expects, that is, they must inherit from the included PowerShell classes and implement a handful of required public methods but most of the logic to connect to the chat network, receive messages, and send messages back is left up to the backend developer.

## Generic Backend

Included in PoshBot are a few classes that backends must inherit.
These classes include methods that PoshBot will call during its processing.
When developing a new backend, these methods will contain the logic to interact with the chat network.
Additional methods or classes specific to the backend can be created if necessary.

### Classes

- [Backend](./backend-class.md)

- [Connection](./connection-class.md)

- [Message](./message-class.md)

- [Person](./person-class.md)

- [Room](./room-class.md)
