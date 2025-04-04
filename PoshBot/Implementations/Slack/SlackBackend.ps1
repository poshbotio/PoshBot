
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Scope = 'Class', Target = '*')]
class SlackBackend : Backend {

    # The types of message that we care about from Slack
    # All othere will be ignored
    [string[]]$MessageTypes = @(
        'channel_rename'
        'member_joined_channel'
        'member_left_channel'
        'message'
        'pin_added'
        'pin_removed'
        'presence_change'
        'reaction_added'
        'reaction_removed'
        'star_added'
        'star_removed'
        'goodbye'
        'bot_message'
    )

    [int]$MaxMessageLength = 3900

    [SlackClient]$Client

    # Import some color defs.
    hidden [hashtable]$_PSSlackColorMap = @{
        aliceblue            = '#F0F8FF'
        antiquewhite         = '#FAEBD7'
        aqua                 = '#00FFFF'
        aquamarine           = '#7FFFD4'
        azure                = '#F0FFFF'
        beige                = '#F5F5DC'
        bisque               = '#FFE4C4'
        black                = '#000000'
        blanchedalmond       = '#FFEBCD'
        blue                 = '#0000FF'
        blueviolet           = '#8A2BE2'
        brown                = '#A52A2A'
        burlywood            = '#DEB887'
        cadetblue            = '#5F9EA0'
        chartreuse           = '#7FFF00'
        chocolate            = '#D2691E'
        coral                = '#FF7F50'
        cornflowerblue       = '#6495ED'
        cornsilk             = '#FFF8DC'
        crimson              = '#DC143C'
        darkblue             = '#00008B'
        darkcyan             = '#008B8B'
        darkgoldenrod        = '#B8860B'
        darkgray             = '#A9A9A9'
        darkgreen            = '#006400'
        darkkhaki            = '#BDB76B'
        darkmagenta          = '#8B008B'
        darkolivegreen       = '#556B2F'
        darkorange           = '#FF8C00'
        darkorchid           = '#9932CC'
        darkred              = '#8B0000'
        darksalmon           = '#E9967A'
        darkseagreen         = '#8FBC8F'
        darkslateblue        = '#483D8B'
        darkslategray        = '#2F4F4F'
        darkturquoise        = '#00CED1'
        darkviolet           = '#9400D3'
        deeppink             = '#FF1493'
        deepskyblue          = '#00BFFF'
        dimgray              = '#696969'
        dodgerblue           = '#1E90FF'
        firebrick            = '#B22222'
        floralwhite          = '#FFFAF0'
        forestgreen          = '#228B22'
        fuchsia              = '#FF00FF'
        gainsboro            = '#DCDCDC'
        ghostwhite           = '#F8F8FF'
        gold                 = '#FFD700'
        goldenrod            = '#DAA520'
        gray                 = '#808080'
        green                = '#008000'
        greenyellow          = '#ADFF2F'
        honeydew             = '#F0FFF0'
        hotpink              = '#FF69B4'
        indianred            = '#CD5C5C'
        indigo               = '#4B0082'
        ivory                = '#FFFFF0'
        khaki                = '#F0E68C'
        lavender             = '#E6E6FA'
        lavenderblush        = '#FFF0F5'
        lawngreen            = '#7CFC00'
        lemonchiffon         = '#FFFACD'
        lightblue            = '#ADD8E6'
        lightcoral           = '#F08080'
        lightcyan            = '#E0FFFF'
        lightgoldenrodyellow = '#FAFAD2'
        lightgreen           = '#90EE90'
        lightgrey            = '#D3D3D3'
        lightpink            = '#FFB6C1'
        lightsalmon          = '#FFA07A'
        lightseagreen        = '#20B2AA'
        lightskyblue         = '#87CEFA'
        lightslategray       = '#778899'
        lightsteelblue       = '#B0C4DE'
        lightyellow          = '#FFFFE0'
        lime                 = '#00FF00'
        limegreen            = '#32CD32'
        linen                = '#FAF0E6'
        maroon               = '#800000'
        mediumaquamarine     = '#66CDAA'
        mediumblue           = '#0000CD'
        mediumorchid         = '#BA55D3'
        mediumpurple         = '#9370DB'
        mediumseagreen       = '#3CB371'
        mediumslateblue      = '#7B68EE'
        mediumspringgreen    = '#00FA9A'
        mediumturquoise      = '#48D1CC'
        mediumvioletred      = '#C71585'
        midnightblue         = '#191970'
        mintcream            = '#F5FFFA'
        mistyrose            = '#FFE4E1'
        moccasin             = '#FFE4B5'
        navajowhite          = '#FFDEAD'
        navy                 = '#000080'
        oldlace              = '#FDF5E6'
        olive                = '#808000'
        olivedrab            = '#6B8E23'
        orange               = '#FFA500'
        orangered            = '#FF4500'
        orchid               = '#DA70D6'
        palegoldenrod        = '#EEE8AA'
        palegreen            = '#98FB98'
        paleturquoise        = '#AFEEEE'
        palevioletred        = '#DB7093'
        papayawhip           = '#FFEFD5'
        peachpuff            = '#FFDAB9'
        peru                 = '#CD853F'
        pink                 = '#FFC0CB'
        plum                 = '#DDA0DD'
        powderblue           = '#B0E0E6'
        purple               = '#800080'
        red                  = '#FF0000'
        rosybrown            = '#BC8F8F'
        royalblue            = '#4169E1'
        saddlebrown          = '#8B4513'
        salmon               = '#FA8072'
        sandybrown           = '#F4A460'
        seagreen             = '#2E8B57'
        seashell             = '#FFF5EE'
        sienna               = '#A0522D'
        silver               = '#C0C0C0'
        skyblue              = '#87CEEB'
        slateblue            = '#6A5ACD'
        slategray            = '#708090'
        snow                 = '#FFFAFA'
        springgreen          = '#00FF7F'
        steelblue            = '#4682B4'
        tan                  = '#D2B48C'
        teal                 = '#008080'
        thistle              = '#D8BFD8'
        tomato               = '#FF6347'
        turquoise            = '#40E0D0'
        violet               = '#EE82EE'
        wheat                = '#F5DEB3'
        white                = '#FFFFFF'
        whitesmoke           = '#F5F5F5'
        yellow               = '#FFFF00'
        yellowgreen          = '#9ACD32'
    }

    SlackBackend ([SlackConnectionConfig]$Config) {
        $conn = [SlackConnection]::New($Config)
        $this.Connection = $conn
        $this.Client = [SlackClient]::new($Config.BotToken)
    }

    # Connect to Slack
    [void]Connect() {
        $this.LogInfo('Connecting to backend')
        $this.LogInfo('Listening for the following message types. All others will be ignored', $this.MessageTypes)
        $this.Connection.Connect()
        $this.BotId = $this.GetBotIdentity()
        $this.LoadUsers()
        $this.LoadRooms()
    }

    # Receive a message from the websocket
    [Message[]]ReceiveMessage() {
        $messages = New-Object -TypeName System.Collections.ArrayList
        try {
            foreach ($slackMessage in $this.Connection.ReadReceiveJob()) {
                $this.LogDebug('Received message', (ConvertTo-Json -InputObject $slackMessage -Depth 15 -Compress))

                $ts = [datetime]::UtcNow.ToFileTimeUtc()
                $slackMessage | ConvertTo-Json -Depth 15 | Out-File "C:/temp/poshbot/$ts.json"

                $eventType = $slackMessage.payload.event.type
                $payload = $slackMessage.payload

                # ** Important safety tip, don't cross the streams **
                # Only return messages that didn't come from the bot
                # else we'd cause a feedback loop with the bot processing
                # it's own responses
                if ($this.MsgFromBot($payload.event.user)) {
                    continue
                }

                # Slack will sometimes send back ephemeral messages from user [SlackBot]. Ignore these
                # These are messages like notifing that a message won't be unfurled because it's already
                # in the channel in the last hour. Helpful message for some, but not for us.
                if ($eventType -eq 'bot_message') {
                    $this.LogDebug('SubType is [bot_message]. Ignoring')
                    continue
                }

                # Ignore "message_replied" subtypes
                # These are message Slack sends to update the client that the original message has a new reply.
                # That reply is sent is another message.
                # We do this because if the original message that this reply is to is a bot command, the command
                # will be executed again so we....need to not do that :)
                if ($eventType -eq 'message_replied') {
                    $this.LogDebug('SubType is [message_replied]. Ignoring')
                    continue
                }

                # We only care about certain message types from Slack
                if ($eventType -in $this.MessageTypes) {

                    $msg = [Message]::new()

                    # Set the message type and optionally the subtype
                    #$msg.Type = $slackMessage.type
                    switch ($eventType) {
                        'channel_rename' {
                            $msg.Type = [MessageType]::ChannelRenamed
                        }
                        'member_joined_channel' {
                            $msg.Type = [MessageType]::Message
                            $msg.SubType = [MessageSubtype]::ChannelJoined
                        }
                        'member_left_channel' {
                            $msg.Type = [MessageType]::Message
                            $msg.SubType = [MessageSubtype]::ChannelLeft
                        }
                        'message' {
                            $msg.Type = [MessageType]::Message
                        }
                        'pin_added' {
                            $msg.Type = [MessageType]::PinAdded
                        }
                        'pin_removed' {
                            $msg.Type = [MessageType]::PinRemoved
                        }
                        'presence_change' {
                            $msg.Type = [MessageType]::PresenceChange
                        }
                        'reaction_added' {
                            $msg.Type = [MessageType]::ReactionAdded
                        }
                        'reaction_removed' {
                            $msg.Type = [MessageType]::ReactionRemoved
                        }
                        'star_added' {
                            $msg.Type = [MessageType]::StarAdded
                        }
                        'star_removed' {
                            $msg.Type = [MessageType]::StarRemoved
                        }
                        'goodbye' {
                            # The 'goodbye' event means Slack wants to cease comminication with us
                            # and they're being nice about it. We need to reestablish the connection.
                            $this.LogInfo('Received [goodbye] event. Reconnecting to Slack backend...')
                            $this.Connection.Reconnect()
                            return $null
                        }
                    }

                    # The channel the message occured in is sometimes
                    # nested in an 'item' property
                    # if ($slackMessage.item -and ($slackMessage.item.channel)) {
                    #     $msg.To = $slackMessage.item.channel
                    # }

                    if ($eventType) {
                        switch ($eventType) {
                            'channel_join' {
                                $msg.Subtype = [MessageSubtype]::ChannelJoined
                            }
                            'channel_leave' {
                                $msg.Subtype = [MessageSubtype]::ChannelLeft
                            }
                            'channel_name' {
                                $msg.Subtype = [MessageSubtype]::ChannelRenamed
                            }
                            'channel_purpose' {
                                $msg.Subtype = [MessageSubtype]::ChannelPurposeChanged
                            }
                            'channel_topic' {
                                $msg.Subtype = [MessageSubtype]::ChannelTopicChanged
                            }
                        }
                    }
                    $this.LogDebug("Message type is [$($msg.Type)`:$($msg.Subtype)]")

                    $msg.RawMessage = $payload.event
                    $this.LogDebug('Payload event', $payload.event)
                    if ($payload.event.text) { $msg.Text = $payload.event.text }
                    if ($payload.event.channel) { $msg.To = $payload.event.channel }
                    if ($payload.event.user) { $msg.From = $payload.event.user }

                    # Resolve From name
                    $msg.FromName = $this.ResolveFromName($msg)

                    # Resolve channel name
                    $msg.ToName = $this.ResolveToName($msg)

                    # Mark as DM
                    if ($msg.To -match '^D') {
                        $msg.IsDM = $true
                    }

                    # Get time of message
                    $unixEpoch = [datetime]'1970-01-01'
                    if ($payload.event.ts) {
                        $msg.Time = $unixEpoch.AddSeconds($payload.event.ts)
                    } else {
                        $msg.Time = [datetime]::UtcNow
                    }

                    # Sometimes the message is nested in a 'message' subproperty. This could be
                    # if the message contained a link that was unfurled.  We would receive a
                    # 'message_changed' message and need to look in the 'message' subproperty
                    # to see who the message was from.  Slack is weird
                    # https://api.slack.com/events/message/message_changed
                    if ($payload.event.message) {
                        if ($payload.event.message.message.user) {
                            $msg.From = $payload.event.message.user
                        }
                        if ($payload.event.message.text) {
                            $msg.Text = $payload.event.message.text
                        }
                    }

                    # Slack displays @mentions like '@devblackops' but internally in the message
                    # it is <@U4AM3SYI8>
                    # Fix that so we actually see the @username
                    $processed = $this._ProcessMentions($msg.Text)
                    $msg.Text = $processed

                    $this.LogDebug('Sending message to main bot', $msg.ToJson())
                    $messages.Add($msg) > $null
                } else {
                    $this.LogDebug("Message type is [$eventType]. Ignoring")
                }
            }
        } catch {
            Write-Error $_
        }

        return $messages
    }

    # Send a Slack ping
    [void]Ping() {
    }

    # Send a message back to Slack
    [void]SendMessage([Response]$Response) {
        # Process any custom responses
        $this.LogDebug("[$($Response.Data.Count)] custom responses")
        foreach ($customResponse in $Response.Data) {

            [string]$sendTo = $Response.To
            if ($customResponse.DM) {
                $sendTo = "@$($this.UserIdToUsername($Response.MessageFrom))"
            }

            switch -Regex ($customResponse.PSObject.TypeNames[0]) {
                '(.*?)PoshBot\.Card\.Response' {
                    $this.LogDebug('Custom response is [PoshBot.Card.Response]')
                    $chunks = $this._ChunkString($customResponse.Text)

                    $blocks = @()
                    $x = 0
                    foreach ($chunk in $chunks) {
                        $fbText = 'no data'
                        if (-not [string]::IsNullOrEmpty($chunk.Text)) {
                            $this.LogDebug("Response size [$($chunk.Text.Length)]")
                            $fbText = $chunk.Text
                        }

                        if ($customResponse.Title) {
                            # If we chunked up the response, only display the title on the first one
                            if ($x -eq 0) {
                                if ($customResponse.LinkUrl) {
                                    $blocks += @{
                                        type = 'section'
                                        text = @{
                                            type = 'mrkdwn'
                                            text = "[$($customResponse.Title)]($($customResponse.LinkUrl))"
                                        }
                                    }
                                } else {
                                    $blocks += @{
                                        type = 'header'
                                        text = @{
                                            type  = 'plain_text'
                                            text  = $customResponse.Title
                                            emoji = $true
                                        }
                                    }
                                }
                            }
                        }

                        if (-not [string]::IsNullOrEmpty($chunk) -and -not $customResponse.ThumbnailUrl) {
                            $blocks += @{
                                type = 'section'
                                text = @{
                                    type = 'mrkdwn'
                                    text = '```' + $chunk + '```'
                                }
                            }
                        }

                        if ($customResponse.ImageUrl) {
                            $blocks += @{
                                type      = 'image'
                                image_url = $customResponse.ImageUrl
                                alt_text  = 'alt text'
                            }
                        }
                        if ($customResponse.ThumbnailUrl) {
                            $blocks += @{
                                type      = 'section'
                                text      = @{
                                    type = 'mrkdwn'
                                    text = [string]::IsNullOrEmpty($chunk) ? ' ' : $chunk
                                }
                                accessory = @{
                                    type      = 'image'
                                    image_url = $customResponse.ThumbnailUrl
                                    alt_text  = 'alt text'
                                }
                            }
                        }

                        if ($customResponse.Fields) {
                            $blocks += @{
                                type   = 'section'
                                fields = @()
                            }
                            foreach ($key in $customResponse.Fields.Keys) {
                                $blocks[-1].fields += @{
                                    type = 'mrkdwn'
                                    text = "*$key*`n$($customResponse.Fields[$key])"
                                }
                            }
                        }

                        $this.LogDebug("Sending card response back to Slack channel [$sendTo]", $blocks)
                        $this.Client.PostCard($sendTo, $blocks, $fbText)
                    }
                    break
                }
                '(.*?)PoshBot\.Text\.Response' {
                    $this.LogDebug('Custom response is [PoshBot.Text.Response]')
                    $chunks = $this._ChunkString($customResponse.Text)
                    foreach ($chunk in $chunks) {
                        if ($customResponse.AsCode) {
                            $t = '```' + $chunk + '```'
                        } else {
                            $t = $chunk
                        }
                        $this.LogDebug("Sending text response back to Slack channel [$sendTo]", $t)
                        $this.Client.PostText($sendTo, $t)
                    }
                    break
                }
                '(.*?)PoshBot\.File\.Upload' {
                    $this.LogDebug('Custom response is [PoshBot.File.Upload]')

                    if (-not (Test-Path -Path $customResponse.Path -ErrorAction SilentlyContinue)) {
                        $this.LogDebug("Unable to find file at [$($customResponse.Path)]")
                    } else {
                        $this.LogDebug("Uploading [$($customResponse.Path)] to Slack channel [$sendTo]")
                        $this.Client.UploadFileToChannel($sendTo, $customResponse.Path, $customResponse.$customResponse.FileName)

                        if (-not $customResponse.KeepFile) {
                            Remove-Item -LiteralPath $customResponse.Path -Force
                        }
                    }

                    break
                }
            }
        }

        if ($Response.Text.Count -gt 0) {
            foreach ($t in $Response.Text) {
                $this.LogDebug("Sending response back to Slack channel [$($Response.To)]", $t)
                $this.Client.PostText($Response.To, $t)
            }
        }
    }

    # Add a reaction to an existing chat message
    [void]AddReaction([Message]$Message, [ReactionType]$Type, [string]$Reaction) {
        if ($Message.RawMessage.ts) {
            if ($Type -eq [ReactionType]::Custom) {
                $emoji = $Reaction
            } else {
                $emoji = $this._ResolveEmoji($Type)
            }

            $body = @{
                name      = $emoji
                channel   = $Message.To
                timestamp = $Message.RawMessage.ts
            } | ConvertTo-Json -Depth 5 -Compress
            $this.LogDebug("Adding reaction [$emoji] to message Id [$($Message.RawMessage.ts)]")
            $resp = $this.Client._SendAPI('reactions.add', $body, 'Post')
            if (-not $resp.ok) {
                $this.LogInfo([LogSeverity]::Error, 'Error adding reaction to message', $resp)
            }
        }
    }

    # Remove a reaction from an existing chat message
    [void]RemoveReaction([Message]$Message, [ReactionType]$Type, [string]$Reaction) {
        if ($Message.RawMessage.ts) {
            if ($Type -eq [ReactionType]::Custom) {
                $emoji = $Reaction
            } else {
                $emoji = $this._ResolveEmoji($Type)
            }

            $body = @{
                name      = $emoji
                channel   = $Message.To
                timestamp = $Message.RawMessage.ts
            } | ConvertTo-Json -Depth 5 -Compress
            $this.LogDebug("Removing reaction [$emoji] from message Id [$($Message.RawMessage.ts)]")
            $resp = $this.Client._SendAPI('reactions.remove', $body, 'Post')
            if (-not $resp.ok) {
                $this.LogInfo([LogSeverity]::Error, 'Error removing reaction from message', $resp)
            }
        }
    }

    # Resolve a channel name to an Id
    [string]ResolveChannelId([string]$ChannelName) {
        if ($ChannelName -match '^#') {
            $ChannelName = $ChannelName.TrimStart('#')
        }
        $channelId = ($this.Connection.LoginData.channels | Where-Object name -eq $ChannelName).id
        if (-not $ChannelId) {
            $channelId = ($this.Connection.LoginData.channels | Where-Object id -eq $ChannelName).id
        }
        $this.LogDebug("Resolved channel [$ChannelName] to [$channelId]")
        return $channelId
    }

    # Populate the list of users the Slack team
    [void]LoadUsers() {
        $this.LogDebug('Getting Slack users')
        $allUsers = $this.Client._SendAPI('users.list', 'Get')
        # $allUsers = Invoke-RestMethod -Uri 'https://slack.com/api/users.list' -Headers @{Authorization = "Bearer $($this.tmp_token)"} -Method Get
        # $allUsers = Get-Slackuser -Token $this.Connection.Config.Credential.GetNetworkCredential().Password -Verbose:$false
        $this.LogDebug("[$($allUsers.members.Count)] users returned")
        $allUsers.members | ForEach-Object {
            $user = [SlackPerson]::new()
            $user.Id = $_.id
            $user.Nickname = $_.name
            $user.FullName = $_.real_name
            $user.FirstName = $_.profile.first_name
            $user.LastName = $_.profile.last_name
            $user.Email = $_.profile.email
            $user.Phone = $_.profile.phone
            $user.Skype = $_.profile.skype
            $user.IsBot = $_.is_bot
            $user.IsAdmin = $_.is_admin
            $user.IsOwner = $_.is_owner
            $user.IsPrimaryOwner = $_.is_primary_owner
            $user.IsUltraRestricted = $_.is_ultra_restricted
            $user.Status = $_.profile.status_text
            $user.TimeZoneLabel = $_.tz_label
            $user.TimeZone = $_.tz
            #$user.Presence = $_.Presence
            $user.Deleted = $_.deleted
            if (-not $this.Users.ContainsKey($_.id)) {
                $this.LogDebug("Adding user [$($_.id):$($_.name)]")
                $this.Users[$_.id] = $user
            }
        }
    }

    # Populate the list of channels in the Slack team
    [void]LoadRooms() {
        $this.LogDebug('Getting Slack channels')
        $r = $this.Client._SendAPI('conversations.list', 'Get')
        # $r = Invoke-RestMethod -Uri 'https://slack.com/api/conversations.list' -Headers @{Authorization = "Bearer $($this.tmp_token)"} -Method Get
        if ($r.ok) {
            $channels = $r.channels | Where-Object { $_.is_archived -eq $false }
            $this.LogDebug("[$($channels.Count)] channels returned")

            $channels.ForEach({
                    $channel = [SlackChannel]::new()
                    $channel.Id = $_.id
                    $channel.Name = $_.name
                    $channel.Topic = $_.topic.value
                    $channel.Purpose = $_.purpose.value
                    $channel.Created = $_.created
                    $channel.Creator = $_.creator
                    $channel.IsArchived = $_.is_archived
                    $channel.IsGeneral = $_.is_general
                    $channel.MemberCount = $_.num_members
                    $this.LogDebug("Adding channel: $($_.id):$($_.name)")
                    $this.Rooms[$_.id] = $channel
                })

            foreach ($key in $this.Rooms.Keys) {
                if ($key -notin $channels.ID) {
                    $this.LogDebug("Removing outdated channel [$key]")
                    $this.Rooms.Remove($key)
                }
            }
        } else {
            $this.LogInfo([LogSeverity]::Error, 'Unable to load rooms', $r)
        }
    }

    # Get the bot identity Id
    [string]GetBotIdentity() {
        $r = $this.Client._SendAPI('auth.test', 'Post')
        if ($r.ok) {
            $this.LogVerbose("Bot identity is [$($r.user_id)]")
            return $r.user_id
        } else {
            throw 'Unable to determine bot identity'
        }
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
    [SlackPerson]GetUser([string]$UserId) {
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
        $user = $this.Users.Values | Where-Object { $_.Nickname -eq $Username }
        $id = $null
        if ($user) {
            $id = $user.Id
        } else {
            # User each doesn't exist or is not in the local cache
            # Refresh it and try again
            $this.LogDebug([LogSeverity]::Warning, "User [$Username] not found. Refreshing users")
            $this.LoadUsers()
            $user = $this.Users.Values | Where-Object { $_.Nickname -eq $Username }
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
            $name = $this.Rooms[$ChannelId].Name
        }
        if ($name) {
            $this.LogDebug("Resolved [$ChannelId] to [$name]")
        } else {
            $this.LogDebug([LogSeverity]::Warning, "Could not resolve channel [$ChannelId]")
        }
        return $name
    }

    # Resolve From name
    [string]ResolveFromName([Message]$Message) {
        $fromName = $null
        if ($Message.From) {
            $fromName = $this.UserIdToUsername($Message.From)
        }
        return $fromName
    }

    # Resolve To name
    [string]ResolveToName([Message]$Message) {
        # Skip DM channels, they won't have names
        $toName = $null
        if ($Message.To -and $Message.To -notmatch '^D') {
            $toName = $this.ChannelIdToName($Message.To)
        }
        return $toName
    }

    # Get all user info by their ID
    [hashtable]GetUserInfo([string]$UserId) {
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
    }

    # Remove extra characters that Slack decorates urls with
    hidden [string] _SanitizeURIs([string]$Text) {
        $sanitizedText = $Text -replace '<([^\|>]+)\|([^\|>]+)>', '$2'
        $sanitizedText = $sanitizedText -replace '<(http([^>]+))>', '$1'
        return $sanitizedText
    }

    # Break apart a string by number of characters
    # This isn't a very efficient method but it splits the message cleanly on
    # whole lines and produces better output
    hidden [Collections.Generic.List[string]] _ChunkString([string]$Text) {

        # Don't bother chunking an empty string
        if ([string]::IsNullOrEmpty($Text)) {
            return $text
        }

        $chunks = [Collections.Generic.List[string]]::new()
        $currentChunkLength = 0
        $currentChunk = ''
        $array = $Text -split [Environment]::NewLine

        foreach ($line in $array) {
            if (($currentChunkLength + $line.Length) -lt $this.MaxMessageLength) {
                $currentChunkLength += $line.Length
                $currentChunk += ($line + [Environment]::NewLine)
            } else {
                $chunks.Add($currentChunk + [Environment]::NewLine)
                $currentChunk = ($line + [Environment]::NewLine)
                $currentChunkLength = $line.Length
            }
        }
        $chunks.Add($currentChunk)

        return $chunks
    }

    # Resolve a reaction type to an emoji
    hidden [string]_ResolveEmoji([ReactionType]$Type) {
        $emoji = [string]::Empty
        Switch ($Type) {
            'Success' { return 'white_check_mark' }
            'Failure' { return 'exclamation' }
            'Processing' { return 'gear' }
            'Warning' { return 'warning' }
            'ApprovalNeeded' { return 'closed_lock_with_key' }
            'Cancelled' { return 'no_entry_sign' }
            'Denied' { return 'x' }
        }
        return $emoji
    }

    # Translate formatted @mentions like <@U4AM3SYI8> into @devblackops
    hidden [string]_ProcessMentions([string]$Text) {
        $processed = $Text

        $mentions = $processed | Select-String -Pattern '(?<name><@[^>]*>*)' -AllMatches | ForEach-Object {
            $_.Matches | ForEach-Object {
                [pscustomobject]@{
                    FormattedId   = $_.Value
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
}

function New-PoshBotSlackBackend {
    <#
    .SYNOPSIS
        Create a new instance of a Slack backend
    .DESCRIPTION
        Create a new instance of a Slack backend
    .PARAMETER Configuration
        The hashtable containing backend-specific properties on how to create the Slack backend instance.
    .EXAMPLE
        PS C:\> $backendConfig = @{
            Name = 'SlackBackend'
            BotToken = '<BOT-TOKEN>' | ConvertTo-SecureString -AsPlainText -Force
            WebSocketToken = '<WEBSOCKET-TOKEN>' | ConvertTo-SecureString -AsPlainText -Force
        }
        PS C:\> $$backend = New-PoshBotSlackBackend -Configuration $backendConfig

        Create a Slack backend using the specified tokens.
    .INPUTS
        Hashtable
    .OUTPUTS
        SlackBackend
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope = 'Function', Target = '*')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Scope = 'Function', Target = '*')]
    [cmdletbinding()]
    param(
        [parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('BackendConfiguration')]
        [hashtable[]]$Configuration
    )

    begin {
        $requiredProperties = @(
            'WebSocketToken', 'BotToken'
        )
    }

    process {
        foreach ($item in $Configuration) {

            # Validate required hashtable properties
            if ($missingProperties = $requiredProperties.Where({ $item.Keys -notcontains $_ })) {
                throw "The following required backend properties are not defined: $($missingProperties -join ', ')"
            }
            Write-Verbose 'Creating new Slack backend instance'

            $connectionConfig = [SlackConnectionConfig]::new()
            $connectionConfig.BotToken = $item.BotToken -is [SecureString] ? $item.BotToken : $item.BotToken | ConvertTo-SecureString -AsPlainText -Force
            $connectionConfig.WebSocketToken = $item.WebSocketToken -is [SecureString] ? $item.WebSocketToken : $item.WebSocketToken | ConvertTo-SecureString -AsPlainText -Force

            $backend = [SlackBackend]::new($connectionConfig)
            if ($item.Name) {
                $backend.Name = $item.Name
            }
            $backend
        }
    }
}

Export-ModuleMember -Function 'New-PoshBotSlackBackend'
