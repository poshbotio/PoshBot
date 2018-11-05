function Invoke-Luis {
    
    [PoshBot.BotCommand(
        Aliases = ('stp')
    )]
    [cmdletbinding()]
    param(
        [parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    $uri = 'LUIS_URI_HERE'
    $q = $Arguments -join ' '

    #New-PoshBotTextResponse -Text "query: $q" -AsCode

    if ($q.StartsWith("-Bot:")) {
        $q = $q.Substring(10)
    }

    #New-PoshBotTextResponse -Text "query: $q" -AsCode
    
    $url = "$($uri)$($q)"
    $LuisResponse = Invoke-RestMethod -Uri $url
    $PredictedTopic = $LuisResponse.topScoringIntent.intent    
    $PredictedTopicConfidence = $LuisResponse.topScoringIntent.score
    $ConfidenceLevel = $PredictedTopicConfidence

    $Resume = [pscustomobject]@{
        "Topic" = $PredictedTopic
        "Confidence" = $PredictedTopicConfidence.ToString('P')
        "User mood" = $LuisResponse.sentimentAnalysis.score.ToString('P')
        "Entities Names" = $LuisResponse.entities|%{$_.Entity}|Out-String
        "Entites Values" =  $LuisResponse.entities|%{$_.resolution.values -join ','}
    }

    if ($ConfidenceLevel -lt 0.5) {
        New-PoshBotCardResponse -Type Error -Title "Confidence < 50%" -Text "I don't understand the question (maybe $($PredictedTopic) ?), sorry I'm still learning!"
       
    }
    elseif ($ConfidenceLevel -lt 0.7) {
        New-PoshBotCardResponse -Type Warning -Title "Confidence < 70%" -Text "I'm not sure to understand the question (maybe $($PredictedTopic) ?), sorry I'm still learning! I suppose you're speaking about $PredictedTopic."
    }
    
    #Show Luis result
    New-PoshBotCardResponse -Title "LUIS query result" -Text "$($resume|fl|Out-String)"

    if ($ConfidenceLevel -gt 0.5) {
        switch ($PredictedTopic) {

            #HELPDESK
            "Hello" {New-PoshBotCardResponse -Title "Bot Response" -Text "Hello Human! how are you ?"}

            "AdminReport" {
                [object[]]$ReportType = $LuisResponse.entities|?{$_.type -eq "ReportType"}
                if ($ReportType -ne $null ) {
                    [string[]]$Names = @()

                    foreach ($report in $ReportType) {
                        $Names += $report.resolution.values[0]
                    }
                    New-PoshBotCardResponse -Title "Bot Response" -Text "You asked an Admin Report on $Names"
                }
                else {
                    New-PoshBotCardResponse -Title "Bot Response" -Text "You asked for an Admin Report, but you didn't specify a report type, or I didn't recognized the specified topic."
                }
            }           
        }
    }
}


Export-ModuleMember Invoke-Luis