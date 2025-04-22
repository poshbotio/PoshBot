class SlackClient {
    [string]$token

    [hashtable]$headers = @{}

    [string]$BaseUri = 'https://slack.com/api/'

    [string]$psEdition

    SlackClient([securestring]$token) {
        # $this.token = $token | ConvertFrom-SecureString -AsPlainText
        $this.token = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($token)
        )
        $this.headers = @{
            Authorization = "Bearer $($this.Token)"
        }

        $this.psEdition = & {
            $ExecutionContext.InvokeCommand.ExpandString('$PSVersionTable.PSEdition')
        }
    }

    [pscustomobject]PostCard([string]$Channel, [hashtable[]]$Blocks, [string]$FallBackText) {
        $body = @{
            channel = $Channel
            blocks  = $Blocks
            text    = $FallBackText
        } | ConvertTo-Json -Depth 10 -Compress
        $r = $this._SendAPI('chat.postMessage', $body, 'Post')

        return $r
    }

    [pscustomobject]PostText([string]$channel, [string]$message) {
        $body = @{
            channel = $channel
            text    = $message
        } | ConvertTo-Json -Depth 5

        $r = $this._SendAPI('chat.postMessage', $body, 'Post')
        return $r
    }

    [pscustomobject]_SendAPI([string]$Function, [string]$Method) {
        $uri = "$($this.BaseUri)/$Function"

        $params = @{
            Uri         = $uri
            Method      = $Method
            Headers     = $this.headers
            ContentType = 'application/json; charset=utf-8'
        }

        if ($this.psEdition -and $this.psEdition -eq 'Core') {
            $params.Add('MaximumRetryCount',3)
            $params.Add('RetryIntervalSec',5)
        }
        $r = Invoke-RestMethod @params
        return $r
    }

    [pscustomobject]_SendAPI([string]$Function, [string]$Body, [string]$Method) {
        $uri = "$($this.BaseUri)/$Function"

        $params = @{
            Uri               = $uri
            Method            = $Method
            Headers           = $this.headers
            Body              = $body
            ContentType       = 'application/json; charset=utf-8'
        }

        if ($this.psEdition -and $this.psEdition -eq 'Core') {
            $params.Add('MaximumRetryCount',3)
            $params.Add('RetryIntervalSec',5)
        }

        $r = Invoke-RestMethod @params
        return $r
    }

    [pscustomobject]UploadFileToChannel([string]$Channel, [string]$FilePath, [string]$FileName) {

        # Get URL to upoad file to
        $body = @{
            filename = $FileName
            length   = (Get-Item $FilePath).Length
        }
        $r = Invoke-RestMethod -Uri "$($this.BaseUri)/files.getUploadURLExternal" -Body $body -Method Get -ContentType 'application/x-www-form-urlencoded; charset=utf-8' -Headers $this.headers

        if ($r.ok) {
            $uploadUrl = $r.upload_url
            $file_id = $r.file_id

            # Upload file
            $r = Invoke-WebRequest -Uri $uploadUrl -Method Post -InFile $FilePath -Headers $this.headers -ContentType 'application/octet-stream'
            if ($r.StatusCode -eq 200) {

                # Shage file with channel
                $completeUploadPayload = @{
                    files      = @(
                        @{
                            id    = $file_id
                            title = $FileName
                        }
                    )
                    channel_id = $Channel
                } | ConvertTo-Json -Compress
                $r = $this._SendAPI('files.completeUploadExternal', $completeUploadPayload, 'Post')
                return $r
            } else {
                throw "Error: $($r.StatusCode) $($r.StatusDescription)"
            }
        } else {
            throw "Error: $($r.error)"
        }
    }
}
