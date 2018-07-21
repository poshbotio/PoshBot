
class TeamsBackend : Backend {

    # The types of message that we care about from Slack
    # All othere will be ignored
    [string[]]$MessageTypes = @(
        'message'
    )

    [string]$TeamId = $null
    [string]$ServiceUrl = $null

    TeamsBackend([TeamsConnectionConfig]$Config) {
        $conn = [TeamsConnection]::new($Config)
        $this.Connection = $conn
    }

    # Connect to Teams
    [void]Connect() {
        $this.LogInfo('Connecting to backend')
        $this.Connection.Connect()
        #$this.BotId = $this.GetBotIdentity()
        $this.LoadUsers()
        $this.LoadRooms()
    }

    [Message[]]ReceiveMessage() {
        $messages = New-Object -TypeName System.Collections.ArrayList
        try {
            # Read the output stream from the receive job and get any messages since our last read
            $jsonResult = $this.Connection.ReadReceiveJob()

            if (-not [string]::IsNullOrEmpty($jsonResult)) {
                $this.LogDebug('Received message', $jsonResult)

                $teamsMessages = @($jsonResult | ConvertFrom-Json)

                foreach ($teamsMessage in $teamsMessages) {

                    $this.SetTeamId($teamsMessage)

                    # We only care about certain message types from Teams
                    if ($teamsMessage.type -in $this.MessageTypes) {
                        $msg = [Message]::new()

                        switch ($teamsMessage.type) {
                            'message' {
                                $msg.Type = [MessageType]::Message
                                break
                            }
                        }
                        $this.LogDebug("Message type is [$($msg.Type)]")

                        if ($teamsMessage.recipient) {
                            $msg.To = $teamsMessage.recipient.id
                        }

                        $msg.RawMessage = $teamsMessage
                        $this.LogDebug('Raw message', $teamsMessage)
                        if ($teamsMessage.text)    {
                            $msg.Text = $teamsMessage.text.Replace('<at>PoshBot</at> ', '')
                        }
                        if ($teamsMessage.channelData) { $msg.To   = $teamsMessage.channelData.clientActivityId }
                        if ($teamsMessage.from) {
                            $msg.From = $teamsMessage.from.id
                            $msg.FromName = $teamsMessage.from.name
                        }

                        # Resolve channel name
                        # TODO

                        # Mark as DM
                        # TODO

                        # Get time of message
                        $msg.Time = [datetime]$teamsMessage.timestamp

                        $messages.Add($msg) > $null
                    } else {
                        $this.LogDebug("Message type is [$($teamsMessage.type)]. Ignoring")
                    }
                }
            }
        } catch {
            $this.LogInfo([LogSeverity]::Error, 'Error authenticating to Teams', [ExceptionFormatter]::Summarize($_))
        }

        return $messages
    }

    [void]Ping() {}

    # Send a message
    [void]SendMessage([Response]$Response) {

        $baseUrl = $Response.OriginalMessage.RawMessage.serviceUrl
        $conversationId = $Response.OriginalMessage.RawMessage.conversation.id
        $activityId = $Response.OriginalMessage.RawMessage.id
        $responseUrl = "$($baseUrl)v3/conversations/$conversationId/activities/$activityId"
        $channelId = $Response.OriginalMessage.RawMessage.channelData.teamsChannelId
        $headers = @{
            Authorization = "Bearer $($this.Connection._AccessTokenInfo.access_token)"
        }

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

                    $jsonResponse = @{
                        type = 'message'
                        from = @{
                            id = $Response.OriginalMessage.RawMessage.recipient.id
                            name = $Response.OriginalMessage.RawMessage.recipient.name
                        }
                        conversation = @{
                            id = $Response.OriginalMessage.RawMessage.conversation.id
                            name = ''
                        }
                        recipient = @{
                            id = $Response.OriginalMessage.RawMessage.from.id
                            name = $Response.OriginalMessage.RawMessage.from.name
                        }
                        text = $customResponse | ConvertTo-Json
                        replyToId = $activityId
                    }
                    $jsonResponse = $jsonResponse | ConvertTo-Json

                    $this.LogDebug("Sending response back to Teams channel [$channelId]")
                    try {
                        $responseParams = @{
                            Uri         = $responseUrl
                            Method      = 'Post'
                            Body        = $jsonResponse
                            ContentType = 'application/json'
                            Headers     = $headers
                        }
                        $teamsResponse = Invoke-RestMethod @responseParams
                    } catch {
                        $this.LogInfo([LogSeverity]::Error, "$($_.Exception.Message)", [ExceptionFormatter]::Summarize($_))
                    }

                    break
                }
                '(.*?)PoshBot\.Text\.Response' {

                    $this.LogDebug('Custom response is [PoshBot.Text.Response]')

                    $jsonResponse = @{
                        type = 'message'
                        from = @{
                            id = $Response.OriginalMessage.RawMessage.recipient.id
                            name = $Response.OriginalMessage.RawMessage.recipient.name
                        }
                        conversation = @{
                            id = $Response.OriginalMessage.RawMessage.conversation.id
                            name = ''
                        }
                        recipient = @{
                            id = $Response.OriginalMessage.RawMessage.from.id
                            name = $Response.OriginalMessage.RawMessage.from.name
                        }
                        text = $customResponse.Text
                        replyToId = $activityId
                    }
                    if ($customResponse.AsCode) {
                        $jsonResponse.text = '<code>' + $jsonResponse.text + '</code>'
                        $jsonResponse.textFormat = 'xml'
                    }
                    $jsonResponse = $jsonResponse | ConvertTo-Json

                    $this.LogDebug("Sending response back to Teams channel [$channelId]")
                    try {
                        $responseParams = @{
                            Uri         = $responseUrl
                            Method      = 'Post'
                            Body        = $jsonResponse
                            ContentType = 'application/json'
                            Headers     = $headers
                        }
                        $teamsResponse = Invoke-RestMethod @responseParams
                    } catch {
                        $this.LogInfo([LogSeverity]::Error, "$($_.Exception.Message)", [ExceptionFormatter]::Summarize($_))
                    }


                    break
                }
                '(.*?)PoshBot\.File\.Upload' {
                    $this.LogDebug('Custom response is [PoshBot.File.Upload]')
                    $contentType = 'application/octet-stream'
                    if (($null -eq $global:IsWindows) -or $global:IsWindows) {

                    } else {
                        if (Get-Command -Name file -CommandType Application) {
                            $contentType =  & file --mime-type -b $customResponse.Path
                        }
                    }

                    $uploadParams = @{
                        type           = $contentType
                        name           = $customResponse.Title
                    }

                    if ((Test-Path $customResponse.Path -ErrorAction SilentlyContinue)) {
                        $bytes = [System.Text.Encoding]::UTF8.GetBytes($customResponse.Path)
                        $uploadParams.originalBase64  = [System.Convert]::ToBase64String($bytes)
                        $uploadParams.thumbnailBase64 = [System.Convert]::ToBase64String($bytes)
                        $this.LogDebug("Uploading [$($customResponse.Path)] to Teams channel [$channelId]")
                        $payLoad = $uploadParams | ConvertTo-Json
                        $this.LogDebug('JSON payload', $payLoad)
                        $attachmentUrl = "$($baseUrl)v3/conversations/$conversationId/attachments"

                        $responseParams = @{
                            Uri         = $attachmentUrl
                            Method      = 'Post'
                            Body        = $payLoad
                            ContentType = 'application/json'
                            Headers     = $headers
                        }
                        $teamsResponse = Invoke-RestMethod @responseParams
                    }

                    break
                }
            }
        }

        # Normal responses
        if ($Response.Text.Count -gt 0) {
            $this.LogDebug("Sending response back to Teams channel [$($Response.To)]")
            $this.SendTeamsMessaage($Response)
        }
    }

    # Add a reaction to an existing chat message
    [void]AddReaction([Message]$Message, [ReactionType]$Type, [string]$Reaction) {
        # NOT IMPLEMENTED YET
    }

    # Remove a reaction from an existing chat message
    [void]RemoveReaction([Message]$Message, [ReactionType]$Type, [string]$Reaction) {
        # NOT IMPLEMENTED YET
    }

    # Populate the list of users the Slack team
    [void]LoadUsers() {
        if (-not [string]::IsNullOrEmpty($this.TeamId)) {
            $this.LogDebug('Getting Teams users')

            # $uri = "$($this.ServiceUrl)v3/converstations/$($this.TeamId)/members/"
            # $headers = @{
            #     Authorization = "Bearer $($this.Connection._AccessTokenInfo.access_token)"
            # }
            #$members = Invoke-RestMethod -Uri $uri -Headers $headers

            # $members | Foreach-Object {
            #     $user = [TeamsPerson]::new()
            #     $user.Id                = $_.id
            #     $user.FirstName         = $_.givenName
            #     $user.LastName          = $_.surname
            #     $user.NickName          = "$($_.givenName) $($_.surname)"
            #     $user.FullName          = "$($_.givenName) $($_.surname)"
            #     $user.Email             = $_.email
            #     $user.UserPrincipalName = $_.userPrincipalName

            #     if (-not $this.Users.ContainsKey($_.ID)) {
            #         $this.LogDebug("Adding user [$($_.ID):$($_.Name)]")
            #         $this.Users[$_.ID] =  $user
            #     }
            # }

            # foreach ($key in $this.Users.Keys) {
            #     if ($key -notin $members.ID) {
            #         $this.LogDebug("Removing outdated user [$key]")
            #         $this.Users.Remove($key)
            #     }
            # }
        }
    }

    # Populate the list of channels in the team
    [void]LoadRooms() {
        if (-not [string]::IsNullOrEmpty($this.TeamId)) {
            $this.LogDebug('Getting Teams channels')

            $uri = "$($this.ServiceUrl)v3/teams/$($this.TeamId)/conversations"
            $headers = @{
                Authorization = "Bearer $($this.Connection._AccessTokenInfo.access_token)"
            }
            $channels = Invoke-RestMethod -Uri $uri -Headers $headers

            if ($channels.conversations) {
                $channels.conversations | ForEach-Object {
                    $channel = [TeamsChannel]::new()
                    $channel.Id = $_.id
                    $channel.Name = $_.name
                    $this.LogDebug("Adding channel: $($_.id):$($_.name)")
                    $this.Rooms[$_.id] = $channel
                }

                foreach ($key in $this.Rooms.Keys) {
                    if ($key -notin $channels.conversations.ID) {
                        $this.LogDebug("Removing outdated channel [$key]")
                        $this.Rooms.Remove($key)
                    }
                }
            }
        }
    }

    [bool]MsgFromBot([string]$From) {
        return $false
    }

    # Get a user by their Id
    [TeamsPerson]GetUser([string]$UserId) {
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
        $user = $this.Users.Values | Where-Object {$_.Nickname -eq $Username}
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

    hidden [void]SetTeamId([pscustomobject]$Message) {
        $firstTime = $false

        # The bot won't know what the Teams ID until we receive
        # the first message after startup (dumb)
        # If this is the first time getting it
        # make sure to load user and channel info
        if ($this.TeamId -ne $Message.channelData.team.id) {
            if ([string]::IsNullOrEmpty($this.TeamId)) {
                $firstTime = $true
            }
            $this.TeamId = $Message.channelData.team.id
        }

        # The Service URL for responding back to Teams MAY change
        # so make sure we always not what it is
        if ($this.ServiceUrl -ne $Message.serviceUrl) {
            $this.ServiceUrl = $Message.serviceUrl
        }

        if ($firstTime) {
            #$this.LoadUsers()
            $this.LoadRooms()
        }
    }

    hidden [void]SendTeamsMessaage([Response]$Response) {
        $baseUrl = $Response.OriginalMessage.RawMessage.serviceUrl
        $conversationId = $Response.OriginalMessage.RawMessage.conversation.id
        $activityId = $Response.OriginalMessage.RawMessage.id
        $responseUrl = "$($baseUrl)v3/conversations/$conversationId/activities/$activityId"
        $channelId = $Response.OriginalMessage.RawMessage.channelData.teamsChannelId
        $headers = @{
            Authorization = "Bearer $($this.Connection._AccessTokenInfo.access_token)"
        }

        if ($Response.Text.Count -gt 0) {
            foreach ($text in $Response.Text) {
                $jsonResponse = @{
                    type = 'message'
                    from = @{
                        id = $Response.OriginalMessage.RawMessage.recipient.id
                        name = $Response.OriginalMessage.RawMessage.recipient.name
                    }
                    conversation = @{
                        id = $Response.OriginalMessage.RawMessage.conversation.id
                        name = ''
                    }
                    recipient = @{
                        id = $Response.OriginalMessage.RawMessage.from.id
                        name = $Response.OriginalMessage.RawMessage.from.name
                    }
                    text = $text
                    replyToId = $activityId
                } | ConvertTo-Json

                $this.LogDebug("Sending response back to Teams channel [$channelId]")
                try {
                    $responseParams = @{
                        Uri         = $responseUrl
                        Method      = 'Post'
                        Body        = $jsonResponse
                        ContentType = 'application/json'
                        Headers     = $headers
                    }
                    #$this.LogDebug('JSON payload', $jsonResponse)
                    $teamsResponse = Invoke-RestMethod @responseParams
                } catch {
                    $this.LogInfo([LogSeverity]::Error, "$($_.Exception.Message)", [ExceptionFormatter]::Summarize($_))
                }
            }
        }
    }
}
function New-PoshBotTeamsBackend {
    <#
    .SYNOPSIS
        Create a new instance of a Microsoft Teams backend
    .DESCRIPTION
        Create a new instance of a Microsoft Teams backend
    .PARAMETER Configuration
        The hashtable containing backend-specific properties on how to create the instance.
    .EXAMPLE
        PS C:\> $backendConfig = @{
            Name = 'TeamsBackend'
            Credential = [pscredential]::new(
                '<BOT-ID>',
                ('<BOT-PASSWORD>' | ConvertTo-SecureString -AsPlainText -Force)
            )
            ServiceBusNamespace = '<SERVICEBUS-NAMESPACE>'
            QueueName           = '<QUEUE-NAME>'
            AccessKeyName       = '<KEY-NAME>'
            AccessKey           = '<SECRET>' | ConvertTo-SecureString -AsPlainText -Force
        }
        PS C:\> $$backend = New-PoshBotTeamsBackend -Configuration $backendConfig

        Create a Microsoft Teams backend using the specified Bot Framework credentials and Service Bus information
    .INPUTS
        Hashtable
    .OUTPUTS
        TeamsBackend
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
            Write-Verbose 'Creating new Teams backend instance'

            $connectionConfig = [TeamsConnectionConfig]::new()
            $connectionConfig.Credential          = $item.Credential
            $connectionConfig.ServiceBusNamespace = $item.ServiceBusNamespace
            $connectionConfig.QueueName           = $item.QueueName
            $connectionConfig.AccessKeyName       = $item.AccessKeyName
            $connectionConfig.AccessKey           = $item.AccessKey

            $backend = [TeamsBackend]::new($connectionConfig)
            if ($item.Name) {
                $backend.Name = $item.Name
            }
            $backend
        }
    }
}

Export-ModuleMember -Function 'New-PoshBotTeamsBackend'
