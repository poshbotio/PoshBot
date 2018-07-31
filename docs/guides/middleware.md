# Middleware Hooks

As of PoshBot `v0.11.0`, it is possible to define custom middleware hooks to be executed at certain events during the command processing life cycle.
These middleware hooks can add centralized authentication logic, custom logging solutions, advanced whitelisting or blacklisting, or any other custom processes.

The middleware is added to the [bot configuration](configuration.md) under the property `MiddlewareConfiguration` and can optionally be saved to disk using [Save-PoshBotConfiguration](./../reference/functions/save-poshbotconfiguration.md).
The command [New-PoshBotConfiguration](./../reference/functions/new-poshbotconfiguration.md) has also been modified to support these life cycle hooks.
The new command [New-PoshBotMiddlewareHook](./../reference/functions/New-PoshBotMiddlewareHook.md) will create an object that can be added to this `MiddlewareConfiguration` property.

## How Middleware Works

At various stages of the command processing life cycle, PoshBot provides the ability for custom scripts to be executed to determine if the command should continue executing.
PoshBot will pass in a `CommandExecutionContext` object that contains information about the command, who initiated it, and other metadata.
The middleware can inspect (and modify) this information as appropriate.
If the middleware determines the command should continue processing, it **MUST** return this `CommandExecutionContext` back to the output stream.
PoshBot will pass this object to the next middleware definition.
If the middleware needs to stop execution of the command, simply return nothing to the output stream or raise a terminating exception with the `throw` statement.

## MiddlewareConfiguration

The `MiddlewareConfiguration` property contains six child properties that contain paths to PowerShell scripts that will be executed during the processing of a command.
More than one middleware hook can be added to each property and will be executed in the order they are added.

### PreReceive

Array of middleware scripts that will run before PoshBot "receives" the message from the backend implementation.
This middleware will receive the original message sent from the chat network and have a chance to modify, analyze, and optionally drop the message before PoshBot continues processing it.

### PostReceive

Array of middleware scripts that will run after a message is "received" from the backend implementation.
This middleware runs after messages have been parsed and matched with a registered command in PoshBot.

### PreExecute

Array of middleware scripts that will run before a command is executed.
This middleware is a good spot to run extra authentication or validation processes before commands are executed.

### PostExecute

Array of middleware scripts that will run after PoshBot commands have been executed.
This middleware is a good spot for custom logging solutions to write command history to a custom location.

### PreResponse

Array of middleware script that will run before command responses are sent to the backend implementation.
This middleware is a good spot for modifying or sanitizing responses before they are sent to the chat network.

### PostResponse

Array of middleware scripts that will run after command responses have been sent to the backend implementation.
This middleware runs after all processing is complete for a command and is a good spot for additional custom logging.

## Authoring Middleware

To add middleware, you need a PoshBot configuration object first. The code below will create a configuration with default values.

```powershell
$config = New-PoshBotConfiguration
```

Next, a new middleware hook is defined using [New-PoshBotMiddlewareHook](./../reference/functions/New-PoshBotMiddlewareHook.md).
This command takes the name of the middleware hook and the path to the PowerShell script to execute.
The script **must** accept the parameters `$Context` and `$Bot` in that order.
PoshBot will dynamically pass in these objects when running the middleware.
The `$Context` object will contain details about the current command that will be executed, who initiated the command, and other metadata you can use to determine if the command should continue to be processed.
The `$Bot` object is the current PoshBot instance and is made available if the middleware needs logging functionality or deeper integration with PoshBot internals.

##### c:/poshbot/middleware/prereceive.ps1

```powershell
param(
    $Context,
    $Bot
)

$Bot.LogInfo('Preparing to receive message')
if ($Context.Message.Text -match "^!about*") {
    $Bot.LogInfo('Dropping [!about] about command')
    return
} else {
    $Context
}
```

```powershell
$preReceiveHook = New-PoshBotMiddlewareHook -Name 'prereceive' -Path 'c:/poshbot/middleware/prereceive.ps1'
```

In the example above, the middleware is performing basic blacklisting by inspecting the raw text message that came from the chat network and doing a regex comparison.
If a match is found, the script returns immediately **without** returning the `$Context` object.
Otherwise the `$Context` object is returned normally.

This middleware is then added to the bot configuration object with the code below.
When adding middleware to the `MiddlewareConfiguration` property, use the `Add()` method, passing in the middleware object, and the type of middleware. The types are `PreReceive`, `PostReceive`, `PreExecute`, `PostExecute`, `PreResponse`, and `PostResponse`.

```powershell
$config.MiddlewareConfiguration.Add($preReceiveHook, 'PreReceive')
```

Similarly, middleware can be removed using the `Remove()` method.

```powershell
$config.MiddlewareConfiguration.Remove($preReceiveHook, 'PreReceive')
```

A new instance of PoshBot is created and starting using the configuration object below.

```powershell
$backend = New-PoshBotSlackBackend -Configuration $config.BackendConfiguration
$bot = New-PoshBotInstance -Backend $backend -Configuration $config
$bot | Start-PoshBot
```

## Examples

### PreReceive Example

A simple example of dropping all messages from users Sally and Bob.

##### c:/poshbot/middleware/dropuser.ps1

```powershell
param(
    $Context,
    $Bot
)

$blacklistedUsers = @('sally', 'bob')
$user = $Context.Message.FromName

$Bot.LogDebug('Running user drop middleware')
if ($blacklistedUsers -contains $user) {
    $Bot.LogInfo("Dropping message from [$user]")
    return
}
$Context
```

```powershell
$userDropHook = New-PoshBotMiddlewareHook -Name 'dropuser' -Path 'c:/poshbot/middleware/dropuser.ps1'
$config.MiddlewareConfiguration.Add($userDropHook, 'PreReceive')
```

### PostReceive Example

Example of logging all messages initiated from a certain user.

##### c:/poshbot/middleware/logmessages.ps1

```powershell
param(
    $Context,
    $Bot
)

$user = $Context.Message.FromName
if ($user -eq 'Bob') {
    $Bot.LogInfo("Logging message from [$user]")
    $userMessagesLog = Join-Path -Path $Bot.Configuration.LogDirectory -ChildPath "$user-messages.json"
    $Context.ToJson() | Out-File -FilePath $userMessagesLog -Append -Force
}

$Context
```

```powershell
$userLogHook = New-PoshBotMiddlewareHook -Name 'logmessages' -Path 'c:/poshbot/middleware/logmessages.ps1'
$config.MiddlewareConfiguration.Add($userLogHook, 'PostReceive')
```

### PreExecute Example

Example of performing custom authentication logic using Active Directory to determine if a user can run a command.

##### c:/poshbot/middleware/adauth.ps1

```powershell
param(
    $Context,
    $Bot
)

$user = $Context.Message.FromName
$adGroup = 'botusers'

$userGroups = (New-Object System.DirectoryServices.DirectorySearcher("(&(objectCategory=User)(samAccountName=$user)))")).FindOne().GetDirectoryEntry().memberOf
if (-not ($userGroups -contains $adGroup)) {
    $Bot.LogInfo("User [$user] is not in AD group [$adGroup]. Bot commands cannot be run.")
    return
} else {
    $Context
}
```

```powershell
$adAuthHook = New-PoshBotMiddlewareHook -Name 'adauth' -Path 'c:/poshbot/middleware/adauth.ps1'
$config.MiddlewareConfiguration.Add($adAuthHook, 'PreExecute')
```

### PostExecute Example

Example of custom logging of all command and results results.

##### c:/poshbot/middleware/logcommandresults.ps1

```powershell
param(
    $Context,
    $Bot
)

$resultsLog = Join-Path -Path $Bot.Configuration.LogDirectory -ChildPath 'commandresults.json'

$commandResult = [pscustomobject]@{
    ParsedCommand = $Context.ParsedCommand.Summarize()
    Results = $context.Result.Summarize()
} | ConvertTo-Json -Depth 15 -Compress

$commandResult | Out-File -FilePath $resultsLog -Append -Force

$Context
```

```powershell
$commandResultsHook = New-PoshBotMiddlewareHook -Name 'commandresults' -Path 'c:/poshbot/middleware/logcommandresults.ps1'
$config.MiddlewareConfiguration.Add($commandResultsHook, 'PostExecute')
```

### PreResponse Example

Example of inspecting command response for Social Security numbers and stripping them if present.

##### c:/poshbot/middleware/sanitizeresponses.ps1

```powershell
param(
    $Context,
    $Bot
)

if ($Context.Response.Text -match '\d\d\d-\d\d-\d\d\d\d') {
    $Bot.LogInfo('Sanitizing response')
    $Context.Response.Text -replace '\d\d\d-\d\d-\d\d\d\d', '###-##-####'
}

$Context
```

```powershell
$sanitizeResponsesHook = New-PoshBotMiddlewareHook -Name 'sanitizeresponses' -Path 'c:/poshbot/middleware/sanitizeresponses.ps1'
$config.MiddlewareConfiguration.Add($sanitizeResponsesHook, 'PreResponse')
```

### PostResponse Example

Example of logging all command responses.

##### c:/poshbot/middleware/logcommandresponses.ps1

```powershell
param(
    $Context,
    $Bot
)

$responseLog = Join-Path -Path $Bot.Configuration.LogDirectory -ChildPath 'responses.json'

$Context.Response.Summarize() |
    ConvertTo-Json -Depth 10 -Compress |
    Out-File -FilePath $responseLog -Append -Force

$Context
```

```powershell
$commandResponseHook = New-PoshBotMiddlewareHook -Name 'commandresponses' -Path 'c:/poshbot/middleware/logcommandresponses.ps1'
$config.MiddlewareConfiguration.Add($commandResponseHook, 'PostResponse')
```

## Performance

Middleware runs in the main PoshBot session and **not** as PowerShell jobs like commands.
This means middleware should be written to execute as quickly as possible to not slow down PoshBots` command processing loop.
