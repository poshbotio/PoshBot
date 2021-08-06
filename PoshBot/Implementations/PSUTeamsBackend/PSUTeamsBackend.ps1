#region Enums
enum LogLevel {
    Verbose
    Debug
    Information
    Warning
    Error
    Fatal
}

enum MessageType {
    Channel
    Group
    Direct
}
enum BaseEndpoint {
    Conversation
    Attachment
}
enum MessageAction {
    Receive
    Response
}

enum MessageServity {
    Normal = 0
    Good = 1
    Warning = 2
    Critical = 3
}

enum ActivityType {
    Message <# Communication between Bot and User.#>
    ContactRelationUpdate <# When the bot is added or removed from a user’s list.#>
    ConversationUpdate <# Bot or other members added to a conversation or metadata of conversation has changed.#>
    DeleteUserData <# Instruction to the bot to delete any data which it might have stored.#>
    EndOfConversation <# Completion of conversation#>
    Event <# Background Communication sent to the bot which is not visible to the user#>
    InstallationUpdate <# Installation or uninstallation of a bot within the organization unit like customer tenant or team.#>
    Invoke <# Type of communication that is sent to the bot to perform any specific task or operation. Microsoft Bot Framework reserves it for internal use.#>
    MessageReaction <# This indicates that the user has reacted to an existing activity. For example, the User clicks on the “Like” button.#>
    Typing <# This indicates that user or bot is compiling a response#>
    MessageUpdate <# Any update on any previous message activity in a conversation.#>
    MessageDelete <# Any deletion on any previous message activity in a conversation.#>
    Suggestions <# This tells a private suggestion to the recipient about another specific activity.#>
    Trace <# A bot can log the internal information of the conversation transcript.#>
    Handoff <# Kind of transferring of the control from the bot to the user about the conversation.#>
}

Enum ActivityAction {

    CreateConversation <# Creates a new conversation. #>
    DeleteActivity <# Deletes an existing activity. #>
    DeleteConversationMember <# Removes a member from a conversation. #>
    GetActivityMembers <# Gets the members of the specified activity within the specified conversation. #>
    GetConversationMember <# Gets details about a member of a conversation. #>
    GetConversationMembers <# Gets the members of the specified conversation. #>
    GetConversationPagedMembers <# Gets the members of the specified conversation one page at a time. #>
    GetConversations<# Gets a list of conversations the bot has participated in. #>
    ReplytoActivity <# Sends an activity (message) to the specified conversation, as a reply to the specified activity. #>
    SendConversationHistory <# Uploads a transcript of past activities to the conversation. #>
    SendtoConversation <# Sends an activity (message) to the end of the specified conversation. #>
    UpdateActivity<# Updates an existing activity. #>
    UploadAttachmenttoChannel <# Uploads an attachment directly into a channel's blob storage. #>
}

#endregion Enums

#region Class Helper Functions
function GetServityColor ([MessageServity]$Sevity) {
    $check = ($Sevity).ToString()
    switch ($check) {
        Good { return '03a800' }
        Warning { return 'ff950a' }
        Critical { return 'ff0a0a' }
        Default { return' 0072c6' }
    }

}
#endregion

class PSUTeamsBackend : Backend {

    PSUTeamsBackend([PSUTeamsBackendConfig]$Config) {
        $conn = [PSUTeamsBackendConnection]::new($Config)
        $this.Connection = $conn
        $this.ReceiverEndpoints = ($this.Connection.ServerEndpoints())
    }

    [void] Connect() {
        $this.LogInfo('Connecting to PSU Server Backend')
        $this.Connection.Connect()
    }

    [bool] HasMessagesInQueue() {
        $ServerStatus = (Invoke-RestMethod -Method GET -Uri $this.ReceiverEndpoints.MessagesCount)
        if ($ServerStatus.Count -gt 0) {
            return $true
        } else {
            return $false
        }
    }


    # Receive a message
    [Message[]]ReceiveMessage() {
        $messages = New-Object -TypeName System.Collections.ArrayList
        
    }
    
    # Send a message
    [void]SendMessage([Response]$Response) {
        # Must be extended by the specific Backend implementation
        throw 'Implement me!'
    }

    # Add a reaction to an existing chat message
    [void]AddReaction([Message]$Message, [ReactionType]$Type, [string]$Reaction) {
        # Must be extended by the specific Backend implementation
        throw 'Implement me!'
    }

    [void]AddReaction([Message]$Message, [ReactionType]$Type) {
        $this.AddReaction($Message, $Type, [string]::Empty)
    }

    # Add a reaction to an existing chat message
    [void]RemoveReaction([Message]$Message, [ReactionType]$Type, [string]$Reaction) {
        # Must be extended by the specific Backend implementation
        throw 'Implement me!'
    }

    [void]RemoveReaction([Message]$Message, [ReactionType]$Type) {
        $this.RemoveReaction($Message, $Type, [string]::Empty)
    }

    

    # Send a ping on the chat network
    [void]Ping() {
        # Only implement this method to send a message back
        # to the chat network to keep the connection open
    }

    # Get a user by their Id
    [Person]GetUser([string]$UserId) {
        # Must be extended by the specific Backend implementation
        throw 'Implement me!'
    }

    # Connect to the chat network
    [void]Connect() {
        $this.Connection.Connect()
    }

    # Disconnect from the chat network
    [void]Disconnect() {
        $this.Connection.Disconnect()
    }

    # Populate the list of users on the chat network
    [void]LoadUsers() {
        # Must be extended by the specific Backend implementation
        throw 'Implement me!'
    }

    # Populate the list of channel or rooms on the chat network
    [void]LoadRooms() {
        # Must be extended by the specific Backend implementation
        throw 'Implement me!'
    }

    # Get the bot identity Id
    [string]GetBotIdentity() {
        # Must be extended by the specific Backend implementation
        throw 'Implement me!'
    }

    # Resolve a user name to user id
    [string]UsernameToUserId([string]$Username) {
        # Must be extended by the specific Backend implementation
        throw 'Implement me!'
    }

    # Resolve a user ID to a username/nickname
    [string]UserIdToUsername([string]$UserId) {
        # Must be extended by the specific Backend implementation
        throw 'Implement me!'
    }

    [hashtable]GetUserInfo([string]$UserId) {
        # Must be extended by the specific Backend implementation
        throw 'Implement me!'
    }

    [string]ChannelIdToName([string]$ChannelId) {
        # Must be extended by the specific Backend implementation
        throw 'Implement me!'
    }

    [Message]ResolveFromName([Message]$Message) {
        # Must be extended by the specific Backend implementation
        throw 'Implement me!'
    }

    [Message]ResolveToName([Message]$Message) {
        # Must be extended by the specific Backend implementation
        throw 'Implement me!'
    }
    
}