class PSUTeamsBackendConnection  : Connection{
    
    [System.Collections.Concurrent.ConcurrentQueue[string]]$MessageQueue = [System.Collections.Concurrent.ConcurrentQueue[string]]@{}

    [string] $MessagingEndpointHost = 'localhost'

    hidden static [string] MessagingEndpointRoute() { return 'itbot/api/messages' }

    hidden static [int] MessagingEndpointPort() { return 8080 }
    
    [PSUTeamsBackendConfig]$Config

    [bool]$Connected

    [hashtable] ServerEndpoints() {
        $RootUri = ('http://{0}:{1}/' -f $this.MessagingEndpointHost , $this.MessagingEndpointPort)
        return @{
            POSTMessage   = ('{0}{1}' -f $RootUri, 'itbot/api/messages')
            MessagesCount = ('{0}{1}' -f $RootUri, 'itbot/api/messagesCount')
            ReadMessages  = ('{0}{1}' -f $RootUri, 'itbot/api/messages')
        }
    }

    PSUTeamsBackendConnection([PSUTeamsBackendConfig]$BackendConfig) {
        $this.Config = $BackendConfig
    }
    [void]Initialize() {
        $BackendServer = $null = [PSUTeamsBackendServer]::new($this.Config)
        $BackendServer.Start()
        
    }
    [void]Authenticate() {
        $LoginUri = 'https://login.microsoftonline.com/botframework.com/oauth2/v2.0/token'
        $request = @{
            'grant_type'    = 'client_credentials'
            'client_id'     = $this.Config.ClientID
            'client_secret' = $this.Config.ClientSecret
            'scope'         = 'https://api.botframework.com/.default'
        }
        $AuthenticationResult = (Invoke-RestMethod -Uri $LoginUri -Method Post -Body $request)
        $this.Token = @{
            AccessToken   = $AuthenticationResult.access_token
            ExpiresIn     = $AuthenticationResult.expires_in
            ExtExpiresIn = $AuthenticationResult.ext_expires_in
            TokenType     = $AuthenticationResult.token_type
        }
    }
    [void]Connect() {
        $this.Initialize()
        $this.Authenticate()
    }
    [void]Disconnect() {}
    
}

<#region 


#endregion#>