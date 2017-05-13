
describe 'New-PoshBotFileUpload' {

    BeforeAll {
        $notepad = Join-Path -Path $env:SystemRoot -ChildPath 'system32/notepad.exe'
    }

    it 'Returns a [PoshBot.File.Upload] object' {
        $resp = New-PoshBotFileUpload -Path $notepad
        $resp.PSObject.TypeNames[0] | should be 'PoshBot.File.Upload'
    }

    it 'Will redirect to DM channel when told' {
        $resp = New-PoshBotFileUpload -Path $notepad -DM
        $resp.DM | should be $true
    }

    it 'Has a valid [Title] field' {
        $resp = New-PoshBotFileUpload -Path $notepad -DM -Title 'Notepad.exe'
        $resp.Title | should be 'Notepad.exe'
    }

    it 'Validates file exists' {
        $guid = (New-Guid).ToString()
        $badFile = Join-Path -Path $env:SystemRoot -ChildPath "system32/$($guid).txt"
        { New-PoshBotFileUpload -Path $badFile } | should throw
    }
}

