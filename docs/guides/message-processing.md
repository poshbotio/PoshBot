
# Message Processing and Execution Flow

At its core, PoshBot is essentially running a continuous message processing and execution loop.
Once PoshBot is started, it connects to a particular backend chat network such as Slack, and begins receiving chat messages and events happening in the various channels.
Each message is parsed and matched against all loaded commands to determine which one to execute.
Once a matching command is found, authorization to execute the command by the calling user is validated by PoshBots' [Command Authorization](command-authorization/overview.md) system.
If authorized, the command is executed in a separate process via a PowerShell job and the results are retrieved.
The job success or failure is determined, the results are returned back to the chat network, and PoshBot repeats the processing loop.


## Command Parsing
Upon receiving a message or event from the network, PoshBot first parses the incoming message into it various parts.

Given the incoming message:
> !myplugin:create-vm --name serverxyz --vcpu 2 --ram 4 --tags 'myapp', 'windows' --env prod 'this is a comment'

PoshBot will parse the message and create the object:
```powershell
Plugin: myplugin
Command: create-vm
From: <your_chat_id>
To: <channel_or_dm_id>
NamedParameters:
  name: serverxyz
  vcpu: 2
  ram: 4
  tags: [
      'myapp',
      'windows'
  ]
  env: prod
PositionalParameters: [
    'this is a comment'
]
```

The `Plugin`, `Command`, `NamedParameters`, and `PositionalParameters` are used to determine what command to execute and what parameters to send to it.

## Command Matching

Now that a message has been received and parsed, PoshBot searches through all loaded commands and attempts to find a match.
If the command was entered fully qualified (e.g., `!myplugin:create-vm`) then only the commands from the `myplugin` plugin will be searched.
If the command was entered as `!create-vm`, then all commands from all plugins will be searched.
PoshBot matches the parsed command object to a plugin command via the [Triggers](triggers.md) object attached to each command.

## Command Authorization

Once a command is found, authorization to execute the command by the user who sent the message in the chat network is validated.
This is done via PoshBots' [Command Authorization](command-authorization/overview.md) system.
Each command can have zero or more [Permissions](command-authorization/permissions.md) assigned.
**If no permissions are assigned, then anyone on the chat network can execute the command**.
Collections of related permissions are assigned to a [Role](command-authorization/roles.md).
One or more roles are then assigned to a [Group](command-authorization/groups.md) along with one or more users.
This links users to what commands they can execute.

## Command Execution

Now that the message has been parsed, and command found and authorized, PoshBot has all the information it needs to execute the command.
Commands are executed in PowerShell jobs to separate the commands from the bot.
This sets up the ability in the future for commands to be executed as different users than the bot instance, as well as potentially on another machine.
The bot is also protected from buggy commands as well.

Once the PowerShell job completes, the `Output`, `Information`, `Verbose`, `Warning`, and `Error` streams are collected.
Success of the command is determined by looking at the job as well as the `Error` stream.
The command execution result is added to a history collection for future inspection as well.

## Command Result

Once the command has finished execution, the result object is evaluated and the output is sent back to the chat network.
If the command had any failures, the result object would reflect that so logic in the [Backend](backends.md) implementation can determine how to format the message.
PoshBot has now finished processing the message and returns to waiting for another incoming message from the chat network.
