enum DiscordMsgSendType {
    WebRequest
    RestMethod
}

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Scope='Class', Target='*')]
class DiscordBackend : Backend {

    [string]$BaseUrl = 'https://discordapp.com/api'

    [string]$GuildId

    hidden [hashtable]$_headers = @{}

    hidden [datetime]$_lastTimeMessageSent = [datetime]::UtcNow

    hidden [hashtable]$_rateLimit = @{
        MaxRetries = 3
        Limit      = 5
        Remaining  = 5
        Reset      = 0
        ResetAfter = 0
    }

    [string[]]$MessageTypes = @(
        'CHANNEL_CREATE'
        'CHANNEL_DELETE'
        'CHANNEL_UPDATE'
        'MESSAGE_CREATE'
        'MESSAGE_DELETE'
        'MESSAGE_UPDATE'
        'MESSAGE_REACTION_ADD'
        'MESSAGE_REACTION_REMOVE'
        'PRESENSE_UPDATE'
    )

    # Plain text responses in Discord can only be 2000 characters
    # We'll chunk up responses if they are bigger than this number
    [int]$MaxMessageLength = 1800

    DiscordBackend ([string]$Token, [string]$ClientId, [string]$GuildId) {
        $config            = [ConnectionConfig]::new()
        $secToken          = $Token | ConvertTo-SecureString -AsPlainText -Force
        $config.Credential = New-Object System.Management.Automation.PSCredential($ClientId, $secToken)
        $this.GuildId      = $GuildId
        $conn              = [DiscordConnection]::New()
        $conn.Config       = $config
        $this.Connection   = $conn
    }

    # Connect to Discord
    [void]Connect() {
        $this.LogInfo('Connecting to backend')
        $this.LogInfo('Listening for the following message types. All others will be ignored', $this.MessageTypes)
        $this.Connection.Connect()
        $this.BotId = $this.GetBotIdentity()
        $this._headers = @{
            Authorization  = "Bot $($this.Connection.Config.Credential.GetNetworkCredential().password)"
            'User-Agent'   = 'PoshBot'
            'Content-Type' = 'application/json'
        }
        $this.LoadUsers()
        $this.LoadRooms()
    }

    # Receive a message from the connection
    [Message[]]ReceiveMessage() {
        $messages = [System.Collections.Generic.List[Message]]::new()

        # Read the output stream from the receive job and get any messages since our last read
        [string[]]$jsonResults = $this.Connection.ReadReceiveJob()
        foreach ($jsonResult in $jsonResults) {
            $this.LogDebug('Received message', $jsonResult)

            # We only care about certain message types from Discord
            $jsonParams = @{
                InputObject = $jsonResult
            }
            if ($global:PSVersionTable.PSVersion.Major -ge 6) {
                $jsonParams['Depth'] = 10
            }
            $discordMsg = ConvertFrom-Json @jsonParams
            if ($discordMsg.t -in $this.MessageTypes) {
                $msg = [Message]::new()
                $msg.Id = $discordMsg.d.id
                switch ($discordMsg.t) {
                    'CHANNEL_UPDATE' {
                        $msg.Type = [MessageType]::ChannelRenamed
                        break
                    }
                    'MESSAGE_CREATE' {
                        $msg.Type = [MessageType]::Message
                        break
                    }
                    'MESSAGE_DELETE' {
                    }
                    'MESSAGE_UPDATE' {
                        $msg.Type = [MessageType]::Message
                        break
                    }
                    'MESSAGE_REACTION_ADD' {
                        $msg.Type = [MessageType]::ReactionAdded
                        $msg.Id   = $discordMsg.message_id
                        $msg.From = $discordMsg.d.user_id
                        break
                    }
                    'MESSAGE_REACTION_REMOVE' {
                        $msg.Type = [MessageType]::ReactionRemoved
                        $msg.Id   = $discordMsg.message_id
                        $msg.From = $discordMsg.d.user_id
                        break
                    }
                    'PRESENSE_UPDATE' {
                        $msg.Type = [MessageType]::PresenceChange
                        break
                    }
                    default {
                        $this.LogDebug("Unknown message type: [$($discordMsg.t)]")
                    }
                }
                $this.LogDebug("Message type is [$($msg.Type)`:$($msg.Subtype)]")
                $msg.RawMessage = $jsonResult
                if ($discordMsg.d.content)    { $msg.Text = $discordMsg.d.content }
                if ($discordMsg.d.channel_id) { $msg.To   = $discordMsg.d.channel_id }
                if ($discordMsg.d.author.id)  { $msg.From = $discordMsg.d.author.id }

                # Resolve From name
                if ($msg.From) {
                    if ($discordMsg.d.author.username) {
                        $msg.FromName = $discordMsg.d.author.username
                    } else {
                        $msg.FromName = $this.UserIdToUsername($msg.From)
                    }
                }

                # Resolve channel name
                if ($msg.To) {
                    $msg.ToName = $this.ChannelIdToName($msg.To)
                }

                # Mark as DM
                if ($msg.To -match '^D') {
                    $msg.IsDM = $true
                }

                # Get time of message
                if ($discordMsg.d.timestamp) {
                    $msg.Time = ([datetime]$discordMsg.d.timestamp).ToUniversalTime()
                } else {
                    $msg.Time = (Get-Date).ToUniversalTime()
                }

                # Discord displays @mentions like '@devblackops' but internally in the message
                # it is <@519392344089559040>
                # Fix that so we actually see the @username
                $processed = $this._ProcessMentions($msg.Text)
                $msg.Text = $processed

                # ** Important safety tip, don't cross the streams **
                # Only return messages that didn't come from the bot
                # else we'd cause a feedback loop with the bot processing
                # it's own responses
                if (-not $this.MsgFromBot($msg.From)) {
                    $messages.Add($msg)
                } else {
                    $this.LogInfo('Message is from bot. Ignoring')
                }
            } else {
                $this.LogDebug("Message type is [$($discordMsg.t)]. Ignoring")
            }
        }

        return $messages
    }

    # Send a message back to Discord
    [void]SendMessage([Response]$Response) {

        $this.LogDebug("[$($Response.Data.Count)] custom responses")
        foreach ($customResponse in $Response.Data) {
            [string]$sendTo = $Response.To

            # Setup a DM channel with the user if
            # The response dictates it
            if ($customResponse.DM) {
                $dmChannel = $this._CreateDmChannel($Response.MessageFrom)
                if ($dmChannel) {
                    $sendTo = $dmChannel.id
                } else {
                    $this.LogInfo([LogSeverity]::Error, "Unable to send response to DM channel")
                    return
                }
            }

            switch -Regex ($customResponse.PSObject.TypeNames[0]) {
                '(.*?)PoshBot\.Card\.Response' {
                    $this.LogDebug('Custom response is [PoshBot.Card.Response]')
                    $chunks = $this._ChunkString($customResponse.Text)

                    $colorHex = $customResponse.Color.TrimStart('#')
                    $colorInt = $this._ConvertColorCode($colorHex)

                    $embed = @{}
                    $firstChunk = $true
                    foreach ($chunk in $chunks) {

                        # Only send these in the first chunk
                        if ($firstChunk) {
                            $embed['color'] = $colorInt

                            if ($customResponse.Title -and $firstChunk) {
                                $embed['title'] = $customResponse.Title
                            }
                            if ($customResponse.ImageUrl -and $firstChunk) {
                                $embed['image'] = @{
                                    url = $customResponse.ImageUrl
                                }
                            }
                            if ($customResponse.ThumbnailUrl -and $firstChunk) {
                                $embed['thumbnail'] = @{
                                    url = $customResponse.ThumbnailUrl
                                }
                            }
                            if ($customResponse.LinkUrl -and $firstChunk) {
                                # TODO
                                # Does Discord have a concept of a Title link like Slack?
                            }


                            if ($customResponse.Fields.Count -gt 0 -and $firstChunk) {
                                $embed['fields'] = $customResponse.Fields.GetEnumerator().ForEach({
                                    # HACK ALERT!!!
                                    # Discord doesn't like field values that are empty strings or just whitespace.
                                    # We still want the field to show up for the end user but also show that there isn't a value.
                                    # We do what we gotta do. ¯\_(ツ)_/¯
                                    $fixedValue = if ([string]::IsNullOrWhiteSpace($_.value)) {
                                        '<no value>'
                                    } else {
                                        $_.value
                                    }
                                    @{
                                        name   = $_.name
                                        value  = $fixedValue
                                        inline = $true
                                    }
                                })
                            }
                        }

                        if (-not [string]::IsNullOrEmpty($chunk) -and $chunk -ne "`r`n") {
                            $text = '```' + $chunk + '```'
                            $embed['description'] = $text
                        } else {
                            #$text = [string]::Empty
                        }

                        $json = @{
                            tts     = $false
                            embed   = $embed
                        } | ConvertTo-Json -Depth 20

                        try {
                            $this.LogDebug("Sending card response back to Discord channel [$sendTo]", $json)
                            $msgPostUrl = '{0}/channels/{1}/messages' -f $this.baseUrl, $sendTo

                            $this._SendDiscordMsg(
                                @{
                                    Uri         = $msgPostUrl
                                    Method      = 'Post'
                                    Body        = $json
                                }
                            )
                        } catch {
                            $this.LogInfo([LogSeverity]::Error, 'Received error while sending response back to Discord', [ExceptionFormatter]::Summarize($_))
                        }
                        $firstChunk = $false
                    }
                    break
                }
                '(.*?)PoshBot\.Text\.Response' {
                    $this.LogDebug('Custom response is [PoshBot.Text.Response]')
                    $chunks = $this._ChunkString($customResponse.Text)
                    foreach ($chunk in $chunks) {
                        if ($customResponse.AsCode) {
                            $text = '```' + $chunk + '```'
                        } else {
                            $text = $chunk
                        }
                        $this.LogDebug("Sending text response back to Discord channel [$sendTo]", $text)
                        $json = @{
                            content = $text
                            tts     = $false
                            embed   = @{}
                        } | ConvertTo-Json
                        $msgPostUrl = '{0}/channels/{1}/messages' -f $this.baseUrl, $sendTo
                        try {
                            $this._SendDiscordMsg(
                                @{
                                    Uri         = $msgPostUrl
                                    Method      = 'Post'
                                    Body        = $json
                                }
                            )
                        } catch {
                            $this.LogInfo([LogSeverity]::Error, 'Received error while sending response back to Discord', [ExceptionFormatter]::Summarize($_))
                        }
                    }
                    break
                }
                '(.*?)PoshBot\.File\.Upload' {
                    $this.LogDebug('Custom response is [PoshBot.File.Upload]')

                    $msgPostUrl = '{0}/channels/{1}/messages' -f $this.baseUrl, $sendTo
                    $form    = @{}
                    $payload = @{
                        tts = $false
                    }
                    if ([string]::IsNullOrEmpty($customResponse.Path) -and (-not [string]::IsNullOrEmpty($customResponse.Content))) {
                        $payload['content'] = $customResponse.Content
                    } else {
                        # Test if file exists and send error response if not found
                        if (-not (Test-Path -Path $customResponse.Path -ErrorAction SilentlyContinue)) {
                            # Mark command as failed since we could't find the file to upload
                            $this.RemoveReaction($Response.OriginalMessage, [ReactionType]::Success)
                            $this.AddReaction($Response.OriginalMessage, [ReactionType]::Failure)
                            $this.LogDebug([LogSeverity]::Error, "File [$($customResponse.Path)] does not exist.")

                            # Send failure message
                            $embed = @{
                                color = $this._ConvertColorCode('#FF0000')
                                title = 'Unknown File'
                                description = "Could not access file [$($customResponse.Path)]"
                            }
                            $json = @{
                                #content = $text
                                tts     = $false
                                embed   = $embed
                            } | ConvertTo-Json -Compress -Depth 20
                            $this.LogDebug("Sending card response back to Discord channel [$sendTo]", $json)
                            $this._SendDiscordMsg(
                                @{
                                    Uri         = $msgPostUrl
                                    Method      = 'Post'
                                    Body        = $json
                                }
                            )
                            break
                        } else {
                            $form['file'] = Get-Item $customResponse.Path
                        }

                        $this.LogDebug("Uploading [$($customResponse.Path)] to Discord channel [$sendTo]")
                    }

                    if (-not [string]::IsNullOrEmpty($customResponse.Title)) {
                        $payload.title = $customResponse.Title
                    }

                    $form['payload_json'] = ConvertTo-Json $payload
                    $this._SendDiscordMsg(
                        @{
                            Uri         = $msgPostUrl
                            Method      = 'Post'
                            ContentType = 'multipart/form-data'
                            Form        = $form
                        }
                    )
                    break
                }
            }
        }

        if ($Response.Text.Count -gt 0) {
            foreach ($text in $Response.Text) {
                $this.LogDebug("Sending response back to Discord channel [$($Response.To)]", $text)
                $json = @{
                    content = $text
                    tts     = $false
                } | ConvertTo-Json -Compress
                $msgPostUrl = '{0}/channels/{1}/messages' -f $this.baseUrl, $Response.To
                try {
                    $this._SendDiscordMsg(
                        @{
                            Uri         = $msgPostUrl
                            Method      = 'Post'
                            Body        = $json
                        }
                    )
                } catch {
                    $this.LogInfo([LogSeverity]::Error, 'Received error while sending response back to Discord', [ExceptionFormatter]::Summarize($_))
                }
            }
        }
    }

    # Add a reaction to an existing chat message
    [void]AddReaction([Message]$Message, [ReactionType]$Type, [string]$Reaction) {
        if ($Type -eq [ReactionType]::Custom) {
            $emoji = $Reaction
        } else {
            $emoji = $this._ResolveEmoji($Type)
        }

        $uri = '{0}/channels/{1}/messages/{2}/reactions/{3}/@me' -f $this.baseUrl, $Message.To, $Message.Id, $emoji
        try {
            $this.LogDebug("Adding reaction [$emoji] to message Id [$($Message.Id)]")
            $this._SendDiscordMsg(
                @{
                    Uri             = $uri
                    Method          = 'Put'
                    Headers         = $this._headers
                }
            )
        } catch {
            $this.LogInfo([LogSeverity]::Error, 'Error adding reaction to message', [ExceptionFormatter]::Summarize($_))
        }

    }

    # Remove a reaction from an existing chat message
    [void]RemoveReaction([Message]$Message, [ReactionType]$Type, [string]$Reaction) {
        if ($Type -eq [ReactionType]::Custom) {
            $emoji = $Reaction
        } else {
            $emoji = $this._ResolveEmoji($Type)
        }

        $uri = '{0}/channels/{1}/messages/{2}/reactions/{3}/@me' -f $this.baseUrl, $Message.To, $Message.Id, $emoji
        try {
            $this.LogDebug("Removing reaction [$emoji] from message Id [$($Message.Id)]")
            $this._SendDiscordMsg(
                @{
                    Uri             = $uri
                    Method          = 'Delete'
                    Headers         = $this._headers
                }
            )
        } catch {
            $this.LogInfo([LogSeverity]::Error, 'Error removing reaction from message', [ExceptionFormatter]::Summarize($_))
        }
    }

    # Resolve a channel name to an Id
    [string]ResolveChannelId([string]$ChannelName) {
        if ($ChannelName -match '^#') {
            $ChannelName = $ChannelName.TrimStart('#')
        }
        $channelId = $this.Rooms.Where({$_.name -eq $ChannelName})[0].id
        if (-not $ChannelId) {
            $channelId = $this.Rooms({$_id -eq $ChannelName})[0].id
        }
        $this.LogDebug("Resolved channel [$ChannelName] to [$channelId]")
        return $channelId
    }

    # Populate the list of users the Discord guild
    [void]LoadUsers() {
        $this.LogDebug('Getting Discord users')
        $membersUrl = "$($this.baseUrl)/guilds/$($this.GuildId)/members?limit=1000"
        $allUsers = $this._SendDiscordMsg(
            @{
                Uri     = $membersUrl
                Headers = $this._headers
            }
        )
        if ($allUsers.Count -ge 1000) {
            $i = 0
            do {
                $i++
                $moreUsers = $this._SendDiscordMsg(
                    @{
                        Uri     = ($membersUrl + "&after$(1000 * $i - 1)")
                        Headers = $this._headers
                    }
                )
                if ($moreUsers) {
                    $allUsers += $moreUsers
                }
            }
            until ($moreUsers -lt 1000)
        }
        $botUser = [pscustomobject]@{
            user = $this._SendDiscordMsg(
                @{
                    Uri     = "$($this.baseUrl)/users/@me"
                    Headers = $this._headers
                }
            )
        }
        $allUsers += $botUser

        $this.LogDebug("[$($allUsers.Count)] users returned")

        $allUsers.ForEach({
            if (-not $this.Users.ContainsKey($_.user.id.ToString())) {
                $this.LogDebug("Adding user [$($_.user.id.ToString()):$($_.user.username)]")
                $user                   = [DiscordUser]::new()
                $user.Id                = $_.user.id.ToString()
                $user.Nickname          = $_.user.username
                $user.Discriminator     = $_.user.discriminator
                $user.Avatar            = $_.user.avatar
                $user.IsBot             = [bool]$_.user.bot
                $user.IsMfaEnabled      = [bool]$_.user.bot
                $user.Locale            = $_.user.locale
                $user.IsVerified        = $_.user.verified
                $user.Email             = $_.user.email
                $user.Flags             = $_.user.flags
                $user.PremiumType       = $_.user.premium_type
                $this.Users[$_.user.id] = $user
            }
        })

        foreach ($key in $this.Users.Keys) {
            if ($key -notin ($allUsers.user | Select-Object -ExpandProperty id)) {
                $this.LogDebug("Removing outdated user [$key]")
                $this.Users.Remove($key)
            }
        }
    }

    # Populate the list of channels in the Discord guild
    [void]LoadRooms() {
        $this.LogDebug('Getting Discord channels')
        $channelsUrl = "$($this.baseUrl)/guilds/$($this.GuildId)/channels"
        $allChannels = $this._SendDiscordMsg(
            @{
                Uri     = $channelsUrl
                Headers = $this._headers
            }
        )
        $this.LogDebug("[$($allChannels.Count)] channels returned")

        $allChannels.Where({[DiscordChannelType]$_.type -eq [DiscordChannelType]::GUILD_TEXT}).ForEach({
            $channel      = [DiscordChannel]::new()
            $channel.Id   = $_.id
            $channel.Type = [DiscordChannelType]$_.type
            $channel.Name = $_.name
            $channel.nsfw = $_.nsfw
            $this.LogDebug("Adding channel: $($_.ID):$($_.Name)")
            $this.Rooms[$_.ID] = $channel
        })

        foreach ($key in $this.Rooms.Keys) {
            if ($key -notin $allChannels.ID) {
                $this.LogDebug("Removing outdated channel [$key]")
                $this.Rooms.Remove($key)
            }
        }
    }

    [void]LoadRoom([string]$ChannelId) {
        if (-not $this.Rooms.ContainsKey($ChannelId)) {
            $channelsUrl = "$($this.baseUrl)/channels/$ChannelId"
            try {
                $channel = $this._SendDiscordMsg(
                    @{
                        Uri     = $channelsUrl
                        Headers = $this._headers
                    }
                )
                $discordChannel      = [DiscordChannel]::new()
                $discordChannel.Id   = $channel.id
                $discordChannel.Name = 'DM' # Discord DM channels don't have names
                $discordChannel.Type = [DiscordChannelType]$channel.type
                $this.LogDebug("Adding channel: [$($channel.id)]")
                $this.Rooms[$channel.id] = $discordChannel
            } catch {
                $this.LogInfo([LogSeverity]::Error, "Unable to resolve channel [$ChannelId]", [ExceptionFormatter]::Summarize($_))
            }
        }
    }

    # Get the bot identity Id
    [string]GetBotIdentity() {
        $id = $this.Connection.Config.Credential.UserName
        $this.LogVerbose("Bot identity is [$id]")
        return $id
    }

    # Determine if incoming message was from the bot
    [bool]MsgFromBot([string]$From) {
        $frombot = ($this.BotId -eq $From)
        if ($fromBot) {
            $this.LogDebug("Message is from bot [From: $From == Bot: $($this.BotId)]. Ignoring")
        } else {
            $this.LogDebug("Message is not from bot [From: $From <> Bot: $($this.BotId)]")
        }
        return $fromBot
    }

    # Get a user by their Id
    [DiscordUser]GetUser([string]$UserId) {
        $user = $this.Users[$UserId]

        if (-not $user) {
            $this.LogDebug([LogSeverity]::Warning, "User [$UserId] not found. Refreshing users")
            $this.LoadUsers()
            $user = $this.Users[$UserId]
        }

        if ($user) {
            $this.LogDebug("Resolved user [$UserId]", $user)
        } else {
            $this.LogDebug([LogSeverity]::Warning, "Could not resolve user [$UserId]")
        }
        return $user
    }

    # Get a user Id by their name
    [string]UsernameToUserId([string]$Username) {
        $Username = $Username.TrimStart('@')
        $user = $this.Users.Values.Where({$_.Nickname -eq $Username})
        $id = $null
        if ($user) {
            $id = $user.Id
        } else {
            # User each doesn't exist or is not in the local cache
            # Refresh it and try again
            $this.LogDebug([LogSeverity]::Warning, "User [$Username] not found. Refreshing users")
            $this.LoadUsers()
            $user = $this.Users.Values | Where-Object {$_.Nickname -eq $Username}
            if (-not $user) {
                $id = $null
            } else {
                $id = $user.Id
            }
        }
        if ($id) {
            $this.LogDebug("Resolved [$Username] to [$id]")
        } else {
            $this.LogDebug([LogSeverity]::Warning, "Could not resolve user [$Username]")
        }
        return $id
    }

    # Get a user name by their Id
    [string]UserIdToUsername([string]$UserId) {
        $name = $null
        if ($this.Users.ContainsKey($UserId)) {
            $name = $this.Users[$UserId].Nickname
        } else {
            $this.LogDebug([LogSeverity]::Warning, "User [$UserId] not found. Refreshing users")
            $this.LoadUsers()
            $name = $this.Users[$UserId].Nickname
        }
        if ($name) {
            $this.LogDebug("Resolved [$UserId] to [$name]")
        } else {
            $this.LogDebug([LogSeverity]::Warning, "Could not resolve user [$UserId]")
        }
        return $name
    }

    # Get the channel name by Id
    [string]ChannelIdToName([string]$ChannelId) {
        $name = $null
        if ($this.Rooms.ContainsKey($ChannelId)) {
            $name = $this.Rooms[$ChannelId].Name
        } else {
            $this.LogDebug([LogSeverity]::Warning, "Channel [$ChannelId] not found. Refreshing channels")
            $this.LoadRooms()
            $this.LoadRoom($ChannelId)
            $name = $this.Rooms[$ChannelId].Name
        }
        if ($name) {
            $this.LogDebug("Resolved [$ChannelId] to [$name]")
        } else {
            $this.LogDebug([LogSeverity]::Warning, "Could not resolve channel [$ChannelId]")
        }
        return $name
    }

    # Get all user info by their ID
    [hashtable]GetUserInfo([string]$UserId) {
        if (-not [string]::IsNullOrEmpty($UserId)) {
            $user = $null
            if ($this.Users.ContainsKey($UserId)) {
                $user = $this.Users[$UserId]
            } else {
                $this.LogDebug([LogSeverity]::Warning, "User [$UserId] not found. Refreshing users")
                $this.LoadUsers()
                $user = $this.Users[$UserId]
            }

            if ($user) {
                $this.LogDebug("Resolved [$UserId] to [$($user.Nickname)]")
                return $user.ToHash()
            } else {
                $this.LogDebug([LogSeverity]::Warning, "Could not resolve channel [$UserId]")
                return $null
            }
        } else {
            return $null
        }
    }

    # TODO
    # May not be needed. Inspect how Discord handles this
    # Remove extra characters that Discord decorates urls with
    hidden [string] _SanitizeURIs([string]$Text) {
        $sanitizedText = $Text -replace '<([^\|>]+)\|([^\|>]+)>', '$2'
        $sanitizedText = $sanitizedText -replace '<(http([^>]+))>', '$1'
        return $sanitizedText
    }

    # Break apart a string by number of characters
    # This isn't a very efficient method but it splits the message cleanly on
    # whole lines and produces better output
    hidden [Collections.Generic.List[string[]]] _ChunkString([string]$Text) {
        $array              = $Text -split [environment]::NewLine
        $chunks             = [Collections.Generic.List[string[]]]::new()
        $currentChunk       = ''
        $currentChunkLength = 0

        foreach ($line in $array) {
            if (-not ($currentChunkLength + $line.Length -ge $this.MaxMessageLength)) {
                $currentChunkLength += $line.Length
                $currentChunk += $line + "`r`n"
            } else {
                $chunks += $currentChunk
                $currentChunk = ''
                $currentChunkLength = 0
            }
        }
        $chunks += $currentChunk

        return $chunks
    }

    # TODO
    # Validate what the Discord emoji names for these are
    # Resolve a reaction type to an emoji
    hidden [string]_ResolveEmoji([ReactionType]$Type) {
        $emoji = [string]::Empty
        Switch ($Type) {
            'Success'        { return "$([char]0x2705)" } # :white_check_mark:
            'Failure'        { return "$([char]0x2757)" } # :exclamation:
            'Processing'     { return "$([char]0x2699)" } # :gear:
            'Warning'        { return "$([char]0x26A0)" } # :warning:
            'ApprovalNeeded' { return "$([regex]::Unescape("\uD83D\uDD10"))"} # :closed_lock_with_key:
            'Cancelled'      { return "$([char]0x26D4)" } # :no_entry:
            'Denied'         { return "$([regex]::Unescape("\uD83D\uDEAB"))"} # :no_entry_sign:
        }
        return $emoji
    }

    # TODO
    # See how Discord sends back @ mentions
    # Translate formatted @mentions like <@519392344089559040> into @devblackops
    hidden [string]_ProcessMentions([string]$Text) {
        $processed = $Text

        $mentions = $processed | Select-String -Pattern '(<@\d+>)' -AllMatches | ForEach-Object {
            $_.Matches | ForEach-Object {
                [pscustomobject]@{
                    FormattedId = $_.Value
                    UnformattedId = $_.Value.TrimStart('<@').TrimEnd('>')
                }
            }
        }
        $mentions | ForEach-Object {
            if ($name = $this.UserIdToUsername($_.UnformattedId)) {
                $processed = $processed -replace $_.FormattedId, "@$name"
                $this.LogDebug($processed)
            } else {
                $this.LogDebug([LogSeverity]::Warning, "Unable to translate @mention [$($_.FormattedId)] into a username")
            }
        }

        return $processed
    }

    hidden [int]_ConvertColorCode([string]$RGB) {
        try {
            $value = [Convert]::ToInt32("0x$RGB", 16)
        } catch {
            $value = [Convert]::ToInt32("0xFF0000", 16)
        }
        return $value
    }

    # Send a message back to Discord
    # Track rate limiting and delay sending if needed
    # Doc: https://discordapp.com/developers/docs/topics/rate-limits
    # Rate limiting logic inspired from Mark Kraus and PSRAW:  https://github.com/markekraus/PSRAW/blob/staging/PSRAW/Public/API/Invoke-RedditRequest.ps1
    hidden [object]_SendDiscordMsg([hashtable]$Params) {

        if (-not $Params['ContentType']) {$Params['ContentType'] = 'application/json'}
        $Params['Verbose']                          = $false
        $Params['UseBasicParsing']                  = $true
        $Params['Headers']                          = $this._headers
        $Params['Headers']['X-RateLimit-Precision'] = 'millisecond'

        $this._WaitRateLimit()

        $succeeded      = $false
        $attempts       = 0
        $responseObject = $null
        $response       = $null
        do {
            try {
                $response  = Invoke-WebRequest @Params
                $succeeded = $true

                $contentType = $this._GetHttpResponseContentType($response)
                if ($contentType -eq 'application/json') {
                    $responseObject = $response.Content | ConvertFrom-Json
                } else {
                    $this.LogInfo([LogSeverity]::Error, 'Unhandled content-type. Response will be raw.')
                    $responseObject = $response.Content
                }
            } catch {
                $exResponse   = $_.Exception.Response
                $responseBody = $_.ErrorDetails.Message
                if ($null -ne $exResponse -and $exResponse.GetType().FullName -like 'System.Net.HttpWebResponse') {
                    $stream          = $exResponse.GetResponseStream()
                    $stream.Position = 0
                    $streamReader    = [System.IO.StreamReader]::new($stream)
                    $responseBody    = $streamReader.ReadToEnd()
                }
                $errorMessage = "Unable to query URI '{0}': {1}: {2}" -f (
                    $Params.Uri,
                    $_.Exception.Message,
                    $responseBody
                )
                $this.LogInfo([LogSeverity]::Error, $errorMessage)

                # 429 - rate limit?
                if ($exResponse.StatusCode -eq 429) {
                    $rateLimitMsg = $responseBody | ConvertFrom-Json
                    $this.LogInfo([LogSeverity]::Warning, $responseBody)
                    [Threading.Thread]::Sleep($rateLimitMsg.retry_after)
                    $attempts++
                }

                $this.LogDebug("Attempted [$attempts] of [$($this._rateLimit.MaxRetries)]")
            }
            $this._UpdateRateLimit($response)
        } until ($succeeded -or ($attempts -eq $this._rateLimit.MaxRetries))

        return $responseObject
    }

    # Pause briefly if we're rate limited
    hidden [void]_WaitRateLimit() {
        if ($this._rateLimit.Remaining -eq 0) {
            $this.LogInfo([LogSeverity]::Warning, "Rate limit reached. Sleeping [$($this._rateLimit.ResetAfter)] milliseconds")
            [Threading.Thread]::Sleep($this._rateLimit.ResetAfter)
        }
    }

    # Update our internal rate limit tracking from the response headers Discord sends back
    hidden [void]_UpdateRateLimit([Microsoft.PowerShell.Commands.WebResponseObject]$Response) {
        $this._rateLimit.Limit      = $Response.Headers.'X-RateLimit-Limit'       | Select-Object -First 1
        $this._rateLimit.Remaining  = $Response.Headers.'X-RateLimit-Remaining'   | Select-Object -First 1
        $this._rateLimit.Reset      = $Response.Headers.'X-RateLimit-Reset'       | Select-Object -First 1
        $this._rateLimit.ResetAfter = $Response.Headers.'X-RateLimit-Reset-After' | Select-Object -First 1
    }

    # Return the content type of the HTTP response
    hidden [string]_GetHttpResponseContentType([Microsoft.PowerShell.Commands.WebResponseObject]$Response) {
        return @(
            $Response.BaseResponse.Content.Headers.ContentType.MediaType
            $Response.BaseResponse.ContentType
        ).Where({-not [string]::IsNullOrEmpty($_)}, 'First', 1)
    }

    # Create a DM channel with a user
    hidden [pscustomobject]_CreateDmChannel([string]$UserId) {
        $json = @{
            recipient_id = $UserId
        } | ConvertTo-Json -Compress
        $channelPostUrl = '{0}/users/@me/channels' -f $this.baseUrl
        $dmChannel = $null
        try {
            $dmChannel = $this._SendDiscordMsg(
                @{
                    Uri         = $channelPostUrl
                    Method      = 'Post'
                    Body        = $json
                }
            )
            $this.LogDebug("DM channel [$($dmChannel.id)] created", $dmChannel)
        } catch {
            $this.LogInfo([LogSeverity]::Error, "Received error while creating DM channel with user [$UserId]", [ExceptionFormatter]::Summarize($_))
        }
        return $dmChannel
    }
}

function New-PoshBotDiscordBackend {
    <#
    .SYNOPSIS
        Create a new instance of a Discord backend
    .DESCRIPTION
        Create a new instance of a Discord backend
    .PARAMETER Configuration
        The hashtable containing backend-specific properties on how to create the Discord backend instance.
    .EXAMPLE
        PS C:\> $backendConfig = @{
            Name = 'DiscordBackend'
            Token = '<DISCORD-BOT-TOKEN-TOKEN>'
            ClientId = '<DISCORD-CLIENT-ID>'
            GuildId = '<DISCORD-GUILD-ID>'
        }
        PS C:\> $backend = New-PoshBotDiscordBackend -Configuration $backendConfig

        Create a Discord backend using the specified connection information.
    .INPUTS
        Hashtable
    .OUTPUTS
        DiscordBackend
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope='Function', Target='*')]
    [cmdletbinding()]
    param(
        [parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('BackendConfiguration')]
        [hashtable[]]$Configuration
    )

    process {
        foreach ($item in $Configuration) {
            if (-not $item.Token -or -not $item.ClientId -or -not $item.GuildId) {
                throw 'Missing required configuration properties ClientID, GuildId, or Token.'
            } else {
                Write-Verbose 'Creating new Discord backend instance'
                $backend = [DiscordBackend]::new($item.Token, $item.ClientId, $item.GuildId)
                if ($item.Name) {
                    $backend.Name = $item.Name
                }
                $backend
            }
        }
    }
}

Export-ModuleMember -Function 'New-PoshBotDiscordBackend'
