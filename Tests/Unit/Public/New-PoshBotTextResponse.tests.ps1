
describe 'New-PoshBotTextResponse' {
    it 'Returns a [PoshBot.Text.Response] object' {
        $resp = New-PoshBotTextResponse -Text 'abc'
        $resp.PSObject.TypeNames[0] | should be 'PoshBot.Text.Response'
    }

    it 'Has a valid [Text] field' {
        $resp = New-PoshBotTextResponse -Text 'abc'
        $resp.Text | should be 'abc'
    }

    it 'Will redirect to DM channel when told' {
        $resp = New-PoshBotTextResponse -Text 'abc' -DM
        $resp.DM | should be $true
    }

    it 'Will wrap in code block when told' {
        $resp = New-PoshBotTextResponse -Text 'abc' -AsCode
        $resp.AsCode | should be $true
    }
}
