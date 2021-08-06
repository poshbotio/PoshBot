
class PSUTeamsBackendServer {

    [PSUTeamsBackendConfig] $ServerConfig
    hidden [PSCustomObject] $ServerAppToken
    [string] $ServerAddress = "http://localhost:8080"
    hidden [System.Diagnostics.Process] $ServerProcess

    PSUTeamsBackendServer([PSUTeamsBackendConfig] $ServerConfig) {
        $this.ServerConfig = $ServerConfig
    }
    
    [void] Start() {

    #Remove-Item $this.ServerConfig.RepoPath -Recurse -Force  -ErrorAction SilentlyContinue
        $this.ServerConfig.Initialize()
        $this.ServerProcess =  Start-Process $this.ServerConfig.ServerExecutable() -PassThru
        
        while ($true) {
            try {
                Invoke-WebRequest "$($this.ServerAddress)/api/v1/alive" | Out-Null
                break
            }
            catch {}
        }
        $this.Connect()
    
        $this.Init()
    }
    [void] Stop() {
        
    }
    [void] Connect(){
        $ServerSession = $null
        Invoke-WebRequest -Uri "$($this.ServerAddress)/api/v1/signin" -Method Post -Body (@{username='admin';password='1234'} | ConvertTo-Json) -SessionVariable 'ServerSession' -ContentType 'application/json'|Out-Null
        $AppToken = (Invoke-WebRequest -Uri "$($this.ServerAddress)/api/v1/apptoken/grant" -WebSession $ServerSession).Content | ConvertFrom-Json
        $this.ServerAppToken = $AppToken
        Connect-UAServer -ComputerName $this.ServerAddress -AppToken $AppToken.token
    }
    hidden [hashtable] ServerAuthHeader(){
        return @{
            Authorization = ("Bearer {0}" -f $this.ServerAppToken.token)
        }
    }
    [void] Init(){
        # $IntegratedEnv = @{
        #     id = 3
        #     name ="Integrated"
        #     path = "PowerShell Version: 7.1.3"
        #     arguments = $null
        #     modules = $null
        #     variables = @("*")
        #     persistentRunspace = $true
        #     psModulePath = $null
        # }

        Set-PSULicense -Key '<License><Terms>PD94bWwgdmVyc2lvbj0iMS4wIj8+CjxMaWNlbnNlVGVybXMgeG1sbnM6eHNpPSJodHRwOi8vd3d3LnczLm9yZy8yMDAxL1hNTFNjaGVtYS1pbnN0YW5jZSIgeG1sbnM6eHNkPSJodHRwOi8vd3d3LnczLm9yZy8yMDAxL1hNTFNjaGVtYSI+CiAgPFN0YXJ0RGF0ZT4yMDIxLTA0LTA3VDIwOjAxOjI0PC9TdGFydERhdGU+CiAgPFVzZXJOYW1lPml0QHNjaG9lbmVzLWxlYmVuLm9yZzwvVXNlck5hbWU+CiAgPFByb2R1Y3ROYW1lPlBvd2VyU2hlbGxVbml2ZXJzYWw8L1Byb2R1Y3ROYW1lPgogIDxFbmREYXRlPjIwMjItMDQtMDdUMjA6MDE6MjQ8L0VuZERhdGU+CiAgPFNlYXROdW1iZXI+MTwvU2VhdE51bWJlcj4KICA8SXNUcmlhbD5mYWxzZTwvSXNUcmlhbD4KPC9MaWNlbnNlVGVybXM+</Terms><Signature>sEumAmcMtdXu2Jnzv77PLRCnUHHJTrWxQBoD8YAeT4eRsbw4NWIB5g==</Signature></License>'
        # Invoke-RestMethod -Method PUT -Uri "$($this.ServerAddress)/api/v1/environment" -Body ($IntegratedEnv|ConvertTo-Json) -ContentType 'application/json' -Headers $this.ServerAuthHeader()
        # Set-PSUSetting -ApiEnvironment 'Integrated' -DefaultEnvironment 'Integrated' -SecurityEnvironment 'Integrated' -PagesEnvironment 'Integrated' -LogLevel 'Informational'
        
        New-PSUEnvironment -Name 'Bot Framework Environment' -Path 'pwsh.exe' -PersistentRunspace -Variables @("*")
        Set-PSUSetting -ApiEnvironment 'Bot Framework Environment' 

#         New-PSUScript -Name 'Server Init' -Environment 'Integrated' -ScriptBlock {
# #region ClassDefinition
#             class ActivityQueue {
#                 [System.Collections.Queue]$Queue
#                 [System.Collections.Generic.Queue[PSCustomObject]]$LastOperations
#                 [int64]$TotalItemsAdded
#                 [int64]$TotalItemsRemoved
#                 ActivityQueue() {
#                     $this.Queue = [System.Collections.Queue]::new()
#                     $this.LastOperations = [System.Collections.Generic.Queue[PscustomObject]]::new()
#                     $this.TotalItemsAdded = 0
#                     $this.TotalItemsRemoved = 0
#                 }
#                 [void] Add($Activity) {
#                     $this.Queue.Enqueue($Activity)
#                     $this.LastOperations.Enqueue(([PSCustomObject]@{Type = 'Add';Timestamp = [datetime]::Now;data = $Activity}))
#                     $this.TotalItemsAdded++
#                 }
#                 [int64] GetQueueCount() {return $this.Queue.Count}
#                 [psobject] ShowNextActivity() {return $this.Queue.Peek()}                
#                 [psobject] GetNextActivity() {
#                     try {
#                         $ReturnObject = $this.Queue.Dequeue()
#                         $this.LastOperations.Enqueue(([PSCustomObject]@{Type = 'removed';timestamp = [datetime]::Now;id = $ReturnObject.id}))
#                         $this.TotalItemsRemoved++
#                     }
#                     catch {$ReturnObject = $null}
            
#                     return $ReturnObject
#                 }
#                 [array] GetAllActivity() {
#                     $result = while ($this.GetQueueCount()) {
#                         $this.GetNextActivity()
#                     }
            
#                     return $result
#                 }
#                 [hashtable] GetStats() {
#                     return @{TotalItemsAdded = $this.TotalItemsAdded;TotalItemsRemoved = $this.TotalItemsRemoved}
#                 }
#                 [psobject] ShowLastOpertation() {return $this.LastOperations.Peek()}                
                
#             }
# #endregion
#         [ActivityQueue]$Cache:ActivityQueue = [ActivityQueue]::new()
#         }
        

        # Invoke-PSUScript -Environment 'Integrated'  -Name 'Server Init.ps1'

    #region Endpoints
    New-PSUEndpoint -Method POST -Url "/itbot/api/managment" -Endpoint {

    if ($null -eq $Cache:ActivityQueue) {
#region ClassDefinition        
        class ActivityQueue {
            [System.Collections.Queue]$Queue
            [System.Collections.Generic.Queue[PSCustomObject]]$LastOperations
            [int64]$TotalItemsAdded
            [int64]$TotalItemsRemoved

            [void] AddActivity($Activity) {
                $this.Queue.Enqueue($Activity)
                $this.LastOperations.Enqueue(([PSCustomObject]@{
                    Type = 'Add'
                    Timestamp = [datetime]::Now
                    data = $Activity
                }))
                $this.TotalItemsAdded++
            }

            [int64] GetQueueCount() {
                return $this.Queue.Count

            }

            [psobject] ShowNextActivity() {
                return $this.Queue.Peek()
            }

            [psobject] GetNextActivity() {
                try {
                    $ReturnObject = $this.Queue.Dequeue()
                    $this.LastOperations.Enqueue(([PSCustomObject]@{
                        Type = 'removed'
                        timestamp = [datetime]::Now
                        id = $ReturnObject.id
                    }))
                    $this.TotalItemsRemoved++
                }
                catch {
                    $ReturnObject = $null
                }
                return $ReturnObject
            }

            [array] GetAllActivity() {
                $result = while ($this.GetQueueCount()) {
                    $this.GetNextActivity()
                }
                return $result
            }

            [hashtable] GetStats() {
                return @{
                    TotalItemsAdded = $this.TotalItemsAdded
                    TotalItemsRemoved = $this.TotalItemsRemoved
                }
            }

            [psobject] ShowLastOpertation() {
                return $this.LastOperations.Peek()
            }

            ActivityQueue() {
                $this.Queue = [System.Collections.Queue]::new()
                $this.LastOperations = [System.Collections.Generic.Queue[PscustomObject]]::new()
                $this.TotalItemsAdded = 0
                $this.TotalItemsRemoved = 0
            }

        }
#endregion    
        $Cache:ActivityQueue = [ActivityQueue]::new()
    } 
    else {
            if ($action) {
                
            } else {
                $Cache:ActivityQueue
            }
    }
    } -Description ""
    New-PSUEndpoint -Method POST -Url "/itbot/api/messages" -Endpoint {
        try {
            $Cache:ActivityQueue.AddActivity($Body)
            ("Added one item to the queue. There are {0} more in there ..." -f $Cache:ActivityQueue.GetQueueCount())
        }
        catch {
            ("Failed! Error: {0}" -f $_.Exception)
        }
    }  -Description "IT Assistent Botframework ChatAPI Enpoint"
    New-PSUEndpoint -Method GET -Url "/itbot/api/message" -Endpoint {
        $ReturnObject = $Cache:ActivityQueue.GetNextActivity()
        
        $ReturnObject
    } -Description "IT Assistent Botframework ChatAPI Enpoint for gettings queued messages" 
    New-PSUEndpoint -Method GET  -Url "/itbot/api/messages" -Endpoint {
        $Activities = New-Object System.Collections.ArrayList
        while ($Cache:ActivityQueue.GetQueueCount()){
            $item = $Cache:ActivityQueue.Queue.Dequeue() |  ConvertFrom-Json -Depth 25  
            $Activities.Add($item) | Out-Null
            
        }
        $Activities | ConvertTo-Json -AsArray -Depth 25 -EnumsAsStrings
    } -Description "IT Assistent Botframework ChatAPI Enpoint for gettings queued messages"
    New-PSUEndpoint -Method GET -Url "/itbot/api/messagescount" -Endpoint {
        @{
            'msg_count' = $Cache:ActivityQueue.GetQueueCount()
        }
    } -Description "IT Assistent Botframework ChatAPI Enpoint for gettings queued messages" 
#endregion Endpoints 
    }
}



