
describe 'New-PoshBotCardResponse' {

    BeforeAll {
        $imgUrl = 'https://github.com/poshbotio/PoshBot/raw/master/Media/poshbot_logo_300_432.png'
        $linkUrl = 'https://github.com/poshbotio/PoshBot'
    }

    it 'Returns a [PoshBot.Card.Response] object' {
        $resp = New-PoshBotCardResponse -Text 'abc'
        $resp.PSObject.TypeNames[0] | should be 'PoshBot.Card.Response'
    }

    it 'Will redirect to DM channel when told' {
        $resp = New-PoshBotCardResponse -Text 'abc' -DM
        $resp.DM | should be $true
    }

    it 'Has a valid [Text] field' {
        $resp = New-PoshBotCardResponse -Text 'abc'
        $resp.Text | should be 'abc'
    }

    it 'Has a valid [Title] field' {
        $resp = New-PoshBotCardResponse -Text 'abc' -Title 'MyTitle'
        $resp.Title | should be 'MyTitle'
    }

    it 'Has a valid [ThumbnailUrl] field' {
        $resp = New-PoshBotCardResponse -Text 'abc' -ThumbnailUrl $imgUrl
        $resp.ThumbnailUrl | should be $imgUrl
    }

    it 'Has a valid [ImageUrl] field' {
        $resp = New-PoshBotCardResponse -Text 'abc' -ImageUrl $imgUrl
        $resp.ImageUrl | should be $imgUrl
    }

    it 'Has a valid [LinkUrl] field' {
        $resp = New-PoshBotCardResponse -Text 'abc' -LinkUrl $linkUrl
        $resp.LinkUrl | should be $linkUrl
    }

    it 'Has a valid [Fields] field' {
        $fields = @{
            prop1 = 'val1'
            prop2 = 'val2'
        }
        $resp = New-PoshBotCardResponse -Text 'abc' -Fields $fields
        $resp.Fields | should be $fields
    }

    it 'Has a valid [CustomData] field' {
        $customData = @{
            prop1 = 'val1'
            prop2 = 'val2'
        } | ConvertTo-Json
        $resp = New-PoshBotCardResponse -Text 'abc' -CustomData $CustomData
        $resp.CustomData | should be $CustomData
    }

    it 'Sets color field properly' {
        $normal = New-PoshBotCardResponse -Text 'abc' -Type Normal
        $warning = New-PoshBotCardResponse -Text 'abc' -Type Warning
        $err = New-PoshBotCardResponse -Text 'abc' -Type Error
        $black = New-PoshBotCardResponse -Text 'abc' -Color '#000000'

        $normal.Color | should be '#008000'
        $warning.Color | should be '#FFA500'
        $err.Color | should be '#FF0000'
        $black.Color | should be '#000000'
        {New-PoshBotCardResponse -Text 'abc' -Color 'asdf'} | should throw
    }
}
