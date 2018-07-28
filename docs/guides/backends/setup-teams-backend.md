
# Setting up Microsoft Teams Backend

1. Deploy Azure Service Bus with the `Basic` tier
2. Create a Service Bus queue called `messages`
  * Set the following properties on the queue:

| Setting | Value |
|---------|-------|
| Message time to live | 1 minute |
| Lock duration        | 30 seconds |
| Duplicate detection history | 10 minutes |
| Maximum delivery count | 10 |
| Maximum Size | 1GB |
| Partitioning | false |
| Move expired messages to dead-letter queue | true |



  * Create a Shared access policy called `receive` for the `messages` queue with `Listen` permission.
  * Make note of policy name and key. These will be needed by the Teams backed in PoshBot to connect to the Service Bus queue
3. Create Azure Function to receive messages from Bot Framework and push to Service Bus. Make sure bindings are `HTTP` in and `Service Bus` out.

#### run.ps1

```powershell
$request = Get-Content $req -Raw

Out-File -Encoding Ascii -FilePath $outputSbMsg -inputObject $request
```

#### function.json

```json
{
  "bindings": [
    {
      "name": "req",
      "type": "httpTrigger",
      "direction": "in",
      "methods": [
        "post"
      ],
      "authLevel": "function"
    },
    {
      "type": "serviceBus",
      "connection": "<SERVICE-BUS-CONNECTION-STRING>",
      "name": "outputSbMsg",
      "queueName": "messages",
      "accessRights": "Send",
      "direction": "out"
    }
  ],
  "disabled": false
}
```

3. Make note of Function URL (including token)

4. Create a new bot in [Bot Framework](https://dev.botframework.com/bots/new)
  * Create new App ID and password. Make note of these. They will be needed by the Teams backend in PoshBot
  * Make note of the bot name. This is globally unique and will be needed by the Teams backend in PoshBot

5. In `Message endpoint` for bot, provide Function URL (including token)

5. Generate new App ID and password for bot

6. Add Teams channel to bot

7. Test Bot Framework

  * Go to Test pane in Bot Framework and send a message.
  * Verify Azure Function received message by looking at function logs
  * Verify message is submitted to Service Bus queue

8. Install [App Studio](https://docs.microsoft.com/en-us/microsoftteams/platform/get-started/get-started-app-studio) in Teams

9. Inside App Studio in Teams, go to `Manifest editor` tab and create a new app.
  * Enter values for all required settings
  * Navigate to `Capabilities -> Bots`
    * Enter name for bot and the App ID you created in Bot Framework
    * Make sure `Personal` and `Team` is selected under `Scope`
    * Go to `Finish -> Test and distribute`
      * Export the bot manifest .zip to your computer.

10. Go to Teams -> Manage Team
  * Go to Apps tab and select `Upload a custom app`. Select the manifest .zip you downloaded.

11. Create Poshbot startup script that uses the values you just setup.

### Example PoshBot startup script

```powershell
Import-Module PoshBot
$pbc = New-PoshBotConfiguration
$pbc.BotAdmins = @('<AAD-USER-PRINCIPAL-NAME>')

$backendConfig = @{
    Name                = 'TeamsBackend'
    BotName             = '<BOT-NAME>'
    TeamId              = '<TEAMS-ID>'
    ServiceBusNamespace = '<SERVICE-BUS-NAMESPACE-NAME>'
    QueueName           = 'messages'
    AccessKeyName       = 'receive'
    AccessKey           = '<SAS-KEY>' | ConvertTo-SecureString -AsPlainText -Force
    Credential          = [pscredential]::new(
        '<BOT-APP-ID>',
        ('<BOT-APP-PASSWORD>' | ConvertTo-SecureString -AsPlainText -Force)
    )
}
$backend = New-PoshBotTeamsBackend -Configuration $backendConfig

$bot = New-PoshBotInstance -Configuration $pbc -Backend $backend
$bot | Start-PoshBot -Verbose
```
