
class SlackBackend : Backend {

    # The types of message that we care about from Slack
    # All othere will be ignored
    [string[]]$MessageTypes

    # Buffer to receive data from websocket
    hidden [Byte[]]$Buffer = (New-Object System.Byte[] 4096)

    # Import some color defs.
    hidden [hashtable]$_PSSlackColorMap = @{
        aliceblue = "#F0F8FF"
        antiquewhite = "#FAEBD7"
        aqua = "#00FFFF"
        aquamarine = "#7FFFD4"
        azure = "#F0FFFF"
        beige = "#F5F5DC"
        bisque = "#FFE4C4"
        black = "#000000"
        blanchedalmond = "#FFEBCD"
        blue = "#0000FF"
        blueviolet = "#8A2BE2"
        brown = "#A52A2A"
        burlywood = "#DEB887"
        cadetblue = "#5F9EA0"
        chartreuse = "#7FFF00"
        chocolate = "#D2691E"
        coral = "#FF7F50"
        cornflowerblue = "#6495ED"
        cornsilk = "#FFF8DC"
        crimson = "#DC143C"
        darkblue = "#00008B"
        darkcyan = "#008B8B"
        darkgoldenrod = "#B8860B"
        darkgray = "#A9A9A9"
        darkgreen = "#006400"
        darkkhaki = "#BDB76B"
        darkmagenta = "#8B008B"
        darkolivegreen = "#556B2F"
        darkorange = "#FF8C00"
        darkorchid = "#9932CC"
        darkred = "#8B0000"
        darksalmon = "#E9967A"
        darkseagreen = "#8FBC8F"
        darkslateblue = "#483D8B"
        darkslategray = "#2F4F4F"
        darkturquoise = "#00CED1"
        darkviolet = "#9400D3"
        deeppink = "#FF1493"
        deepskyblue = "#00BFFF"
        dimgray = "#696969"
        dodgerblue = "#1E90FF"
        firebrick = "#B22222"
        floralwhite = "#FFFAF0"
        forestgreen = "#228B22"
        fuchsia = "#FF00FF"
        gainsboro = "#DCDCDC"
        ghostwhite = "#F8F8FF"
        gold = "#FFD700"
        goldenrod = "#DAA520"
        gray = "#808080"
        green = "#008000"
        greenyellow = "#ADFF2F"
        honeydew = "#F0FFF0"
        hotpink = "#FF69B4"
        indianred = "#CD5C5C"
        indigo = "#4B0082"
        ivory = "#FFFFF0"
        khaki = "#F0E68C"
        lavender = "#E6E6FA"
        lavenderblush = "#FFF0F5"
        lawngreen = "#7CFC00"
        lemonchiffon = "#FFFACD"
        lightblue = "#ADD8E6"
        lightcoral = "#F08080"
        lightcyan = "#E0FFFF"
        lightgoldenrodyellow = "#FAFAD2"
        lightgreen = "#90EE90"
        lightgrey = "#D3D3D3"
        lightpink = "#FFB6C1"
        lightsalmon = "#FFA07A"
        lightseagreen = "#20B2AA"
        lightskyblue = "#87CEFA"
        lightslategray = "#778899"
        lightsteelblue = "#B0C4DE"
        lightyellow = "#FFFFE0"
        lime = "#00FF00"
        limegreen = "#32CD32"
        linen = "#FAF0E6"
        maroon = "#800000"
        mediumaquamarine = "#66CDAA"
        mediumblue = "#0000CD"
        mediumorchid = "#BA55D3"
        mediumpurple = "#9370DB"
        mediumseagreen = "#3CB371"
        mediumslateblue = "#7B68EE"
        mediumspringgreen = "#00FA9A"
        mediumturquoise = "#48D1CC"
        mediumvioletred = "#C71585"
        midnightblue = "#191970"
        mintcream = "#F5FFFA"
        mistyrose = "#FFE4E1"
        moccasin = "#FFE4B5"
        navajowhite = "#FFDEAD"
        navy = "#000080"
        oldlace = "#FDF5E6"
        olive = "#808000"
        olivedrab = "#6B8E23"
        orange = "#FFA500"
        orangered = "#FF4500"
        orchid = "#DA70D6"
        palegoldenrod = "#EEE8AA"
        palegreen = "#98FB98"
        paleturquoise = "#AFEEEE"
        palevioletred = "#DB7093"
        papayawhip = "#FFEFD5"
        peachpuff = "#FFDAB9"
        peru = "#CD853F"
        pink = "#FFC0CB"
        plum = "#DDA0DD"
        powderblue = "#B0E0E6"
        purple = "#800080"
        red = "#FF0000"
        rosybrown = "#BC8F8F"
        royalblue = "#4169E1"
        saddlebrown = "#8B4513"
        salmon = "#FA8072"
        sandybrown = "#F4A460"
        seagreen = "#2E8B57"
        seashell = "#FFF5EE"
        sienna = "#A0522D"
        silver = "#C0C0C0"
        skyblue = "#87CEEB"
        slateblue = "#6A5ACD"
        slategray = "#708090"
        snow = "#FFFAFA"
        springgreen = "#00FF7F"
        steelblue = "#4682B4"
        tan = "#D2B48C"
        teal = "#008080"
        thistle = "#D8BFD8"
        tomato = "#FF6347"
        turquoise = "#40E0D0"
        violet = "#EE82EE"
        wheat = "#F5DEB3"
        white = "#FFFFFF"
        whitesmoke = "#F5F5F5"
        yellow = "#FFFF00"
        yellowgreen = "#9ACD32"
    }

    SlackBackend ([string]$Token) {
        Import-Module PSSlack -Verbose:$false -ErrorAction Stop

        $config = [ConnectionConfig]::new()
        $secToken = $Token | ConvertTo-SecureString -AsPlainText -Force
        $config.Credential = New-Object System.Management.Automation.PSCredential('asdf', $secToken)
        $conn = [SlackConnection]::New()
        $conn.Config = $config
        $this.Connection = $conn
        $this.MessageTypes = @('message', 'channel_join', 'channel_leave', 'channel_topic')
    }

    [void]Connect() {
        $this.Connection.Connect()
        $this.BotId = $this.GetBotIdentity()
        $this.LoadUsers()
        $this.LoadRooms()
    }

    # Receive a message from the websocket
    [Message]ReceiveMessage() {
        [Message]$msg = $null
        try {
            # This will block waiting to receive something so let's manage that with a
            # short lived cancellation token
            # $cts = New-Object System.Threading.CancellationTokenSource -ArgumentList 5000
            # $jsonResult = [string]::Empty
            # $task = $this.Connection.WebSocket.ReceiveAsync($this.buffer, $cts.Token)
            # if ($task.Exception) {
            #     Write-Error "$($Task | Format-List * | Out-String)"
            #     #$this.Connection.Disconnect([System.Net.WebSockets.WebSocketCloseStatus]::EndpointUnavailable)
            #     #throw $task.Exception.ToString()
            # }
            # do { Start-Sleep -Milliseconds 100 }
            # until ($task.IsCompleted -or $task.IsCancelled)

            # # Get result from socket
            # if ($task.IsCompleted -and -not $task.IsCancelled) {
            #     $jsonResult = [System.Text.Encoding]::UTF8.GetString($this.buffer, 0, $task.Result.Count)
            # }

            $cts = New-Object System.Threading.CancellationTokenSource
            $taskResult = $this.Connection.WebSocket.ReceiveAsync($this.buffer, $cts.Token).GetAwaiter().GetResult()
            $jsonResult = [System.Text.Encoding]::UTF8.GetString($this.buffer, 0, $taskResult.Count)

            if ($null -ne $jsonResult -and $jsonResult -ne [string]::Empty) {
                Write-Debug -Message "[SlackBackend:ReceiveMessage] Received `n$jsonResult"

                $slackMessage = $jsonResult | ConvertFrom-Json
                if ($slackMessage) {
                    # We only care about certain message types from Slack
                    if ($slackMessage.Type -in $this.MessageTypes) {
                        $msg = [Message]::new()
                        $msg.Type = $slackMessage.type
                        $msg.RawMessage = $slackMessage
                        if ($slackMessage.text)    { $msg.Text = $slackMessage.text }
                        if ($slackMessage.channel) { $msg.To   = $slackMessage.channel }
                        if ($slackMessage.user)    { $msg.From = $slackMessage.user }
                        if (-not $this.MsgFromBot($msg.From)) {
                            return $msg
                        } else {
                            # Don't process messages that came from the bot
                            # That could cause a feedback loop
                            return $null
                        }

                    }
                }
            }
        } catch {
            Write-Error [ExceptionFormatter]::ToJson($_)
        }
        return $msg
    }

    # Send a Slack ping
    [void]Ping() {
        $msg = @{
            id = 1
            type = 'ping'
            time = [System.Math]::Truncate((Get-Date -Date (Get-Date) -UFormat %s))
        }
        $json = $msg | ConvertTo-Json
        $bytes = ([System.Text.Encoding]::UTF8).GetBytes($json)
        Write-Debug -Message '[SlackBackend:Ping]: One ping only Vasili'
        $cts = New-Object System.Threading.CancellationTokenSource -ArgumentList 5000

        $task = $this.Connection.WebSocket.SendAsync($bytes, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, $cts.Token)
        do { Start-Sleep -Milliseconds 100 }
        until ($task.IsCompleted)
        #$result = $this.Connection.WebSocket.SendAsync($bytes, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, $cts.Token).GetAwaiter().GetResult()
    }

    [void]SendMessage([Card]$Response) {
        $channelId = $this.ResolveChannelId($Response.To)
        if ($channelId) {
            $cardParams = @{
                #Color = $this._PSSlackColorMap.green
                Fallback = $Response.Text
                Text = $Response.Text
                MarkDownFields = 'text'
            }
            if ($Response.Title) { $cardParams.Title = $Response.Title }
            if ($Response.Summary) { $cardParams.PreText = $Response.Summary }
            if ($Response.Link) { $cardParams.TitleLink = $Response.Link }
            if ($Response.ThumbnailUrl) { $cardParams.ThumbURL = $Response.ThumbnailUrl }
            if ($Response.Fields) {
                # Convert hashtable to what Slack expects
                $fields = @()
                foreach($key in $Response.Fields.Keys){
                    $fields += @{
                        title = $key
                        value = $Response.Fields[$key]
                        short = $true
                    }
                }
                $cardParams.Fields = $fields
            }
            $msgAtt = New-SlackMessageAttachment @cardParams

            # Set severity of response
            switch ($Response.Severity) {
                'Success' {
                    $msgAtt.color = $this._PSSlackColorMap.green
                }
                'Warning' {
                    $msgAtt.color = $this._PSSlackColorMap.orange
                }
                'Error' {
                    $msgAtt.color = $this._PSSlackColorMap.red
                }
                'None' {
                    # no color
                }
            }

            $msg = $msgAtt | New-SlackMessage -Channel $Response.To -AsUser
            $slackResponse = $msg | Send-SlackMessage -Token $this.Connection.Config.Credential.GetNetworkCredential().Password -Verbose:$false
            Write-Verbose "[SlackBackend:SendMessage] Result: $($slackResponse | Format-List * | Out-String)"
        } else {
            Write-Error -Message "[SlackBackend:SendMessage] Unable to resolve channel [$($Response.To))]"
        }
    }

    [void]SendMessage([Response]$Response) {
        $channelId = $this.ResolveChannelId($Response.To)
        if ($channelId) {
            $textBlock = '```' + $Response.Text + '```'
            if (($Response.Text -eq [string]::Empty) -or ($null -eq $Response.Text)) {
                $fbText = 'no data'
            } else {
                $fbText = $Response.Text
            }

            $msgAtt = New-SlackMessageAttachment -Fallback $fbText -Text $textBlock -MarkDownFields 'text'

            switch ($Response.Severity) {
                'Success' {
                    $msgAtt.color = $this._PSSlackColorMap.green
                }
                'Warning' {
                    $msgAtt.color = $this._PSSlackColorMap.orange
                }
                'Error' {
                    $msgAtt.color = $this._PSSlackColorMap.red
                }
                'None' {
                    # no color
                }
            }

            $msg = $msgAtt | New-SlackMessage -Channel $Response.To -AsUser
            $slackResponse = $msg | Send-SlackMessage -Token $this.Connection.Config.Credential.GetNetworkCredential().Password -Verbose:$false
            Write-Verbose "[SlackBackend:SendMessage] Result: $($slackResponse | Format-List * | Out-String)"
        } else {
            Write-Error -Message "[SlackBackend:SendMessage] Unable to resolve channel [$($Response.To))]"
        }
    }

    [string]ResolveChannelId([string]$ChannelName) {
        if ($ChannelName -match '^#') {
            $ChannelName = $ChannelName.TrimStart('#')
        }
        $channelId = ($this.Connection.LoginData.channels | Where-Object name -eq $ChannelName).id
        if (-not $ChannelId) {
            $channelId = ($this.Connection.LoginData.channels | Where-Object id -eq $ChannelName).id
        }
        return $channelId
    }

    [void]LoadUsers() {
        $allUsers = Get-Slackuser -Token $this.Connection.Config.Credential.GetNetworkCredential().Password -Verbose:$false
        $allUsers | ForEach-Object {
            $user = [SlackPerson]::new()
            $user.Id = $_.ID
            $user.Nickname = $_.Name
            $user.FullName = $_.RealName
            $user.FirstName = $_.FirstName
            $user.LastName = $_.LastName
            $user.Email = $_.Email
            $user.Phone = $_.Phone
            $user.Skype = $_.Skype
            $user.IsBot = $_.IsBot
            $user.IsAdmin = $_.IsAdmin
            $user.IsOwner = $_.IsOwner
            $user.IsPrimaryOwner = $_.IsPrimaryOwner
            $user.IsUltraRestricted = $_.IsUltraRestricted
            $user.Status = $_.Status
            $user.TimeZoneLabel = $_.TimeZoneLabel
            $user.TimeZone = $_.TimeZone
            $user.Presence = $_.Presence
            $user.Deleted = $_.Deleted
            Write-Verbose -Message "[SlackBackend:LoadUsers] Adding user: $($_.ID):$($_.Name)"
            $this.Users[$_.ID] =  $user
        }

        foreach ($key in $this.Users.Keys) {
            if ($key -notin $allUsers.ID) {
                $this.Users.Remove($key)
            }
        }
    }

    [void]LoadRooms() {
        $allChannels = Get-SlackChannel -Token $this.Connection.Config.Credential.GetNetworkCredential().Password -ExcludeArchived -Verbose:$false

        $allChannels | ForEach-Object {
            $channel = [SlackChannel]::new()
            $channel.Id = $_.ID
            $channel.Name = $_.Name
            $channel.Topic = $_.Topic
            $channel.Purpose = $_.Purpose
            $channel.Created = $_.Created
            $channel.Creator = $_.Creator
            $channel.IsArchived = $_.IsArchived
            $channel.IsGeneral = $_.IsGeneral
            $channel.MemberCount = $_.MemberCount
            foreach ($member in $_.Members) {
                $channel.Members.Add($member, $null)
            }
            Write-Verbose -Message "[SlackBackend:LoadRooms] Adding channel: $($_.ID):$($_.Name)"
            $this.Rooms[$_.ID] = $channel
        }

        foreach ($key in $this.Rooms.Keys) {
            if ($key -notin $allChannels.ID) {
                $this.Rooms.Remove($key)
            }
        }
    }

    [string]GetBotIdentity() {
        return $this.Connection.LoginData.self.id
    }

    [bool]MsgFromBot([string]$From) {
        return $this.BotId -eq $From
    }

    [SlackPerson]GetUser([string]$UserId) {
        $user = $this.Users[$UserId]
        if ($user) {
            return $user
        } else {
            $this.LoadUsers()
            return $this.Users[$UserId]
        }
    }

    [string]UsernameToUserId([string]$Username) {
        $Username = $Username.TrimStart('@')
        $user = (Get-SlackUser -Token $this.Connection.Config.Credential.GetNetworkCredential().Password -Name $Username -Verbose:$false -ErrorAction SilentlyContinue)
        return $user.Id
    }

    [string]UserIdToUsername([string]$UserId) {
        if ($this.Users.ContainsKey($UserId)) {
            return $this.Users[$UserId].Name
        } else {
            $allUsers = Get-SlackUser -Token $this.Connection.Config.Credential.GetNetworkCredential().Password
            return $allUsers | Where-Object {$_.Id -eq $UserId} | Select-Object -ExpandProperty Name
        }
    }
}

function New-PoshBotSlackBackend {
    param(
        [parameter(Mandatory)]
        [string]$BotToken,

        [string]$Name
    )

    $backend = [SlackBackend]::New($BotToken)

    if ($PSBoundParameters.ContainsKey('Name')) {
        $backend.Name = $Name
    }

    return $backend
}
