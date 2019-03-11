
describe 'New-PoshBotFileUpload' {

    BeforeAll {
        $readme = Join-Path -Path $env:BHProjectPath -ChildPath 'README.md'
    }

    it 'Returns a [PoshBot.File.Upload] object' {
        $resp = New-PoshBotFileUpload -Path $readme
        $resp.PSObject.TypeNames[0] | should be 'PoshBot.File.Upload'
    }

    it 'Will redirect to DM channel when told' {
        $resp = New-PoshBotFileUpload -Path $readme -DM
        $resp.DM | should be $true
    }

    it 'Has a valid [Title] field' {
        $resp = New-PoshBotFileUpload -Path $readme -DM -Title 'README.md'
        $resp.Title | should be 'README.md'
    }

    it 'Validates file exists' {
        $guid = (New-Guid).ToString()
        $badFile = Join-Path -Path $env:BHProjectPath -ChildPath "$($guid).txt"
        { New-PoshBotFileUpload -Path $badFile } | should throw
    }

    it 'Sends file content and not path' {
        $resp = New-PoshBotFileUpload -Content 'foo'
        $resp.Path | should be $null
    }

    it 'Has a valid [FileName] field when sending file content' {
        $resp = New-PoshBotFileUpload -Content 'foo' -FileName 'foo.txt'
        $resp.FileName | should be 'foo.txt'
    }

    it 'Has a valid [FileType] field when sending file content' {
        $resp = New-PoshBotFileUpload -Content 'foo' -FileType 'powershell'
        $resp.FileType | should be 'powershell'
    }

    it 'Sends file path and not content' {
        $resp = New-PoshBotFileUpload -Path $readme
        $resp.Content | should be $null
    }


}

