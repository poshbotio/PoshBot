function Slap {
    <#
    .SYNOPSIS
        Slap a user with a large trout
    .PARAMETER User
        The user that will be slapped
    .EXAMPLE
        !slap --user jaap
    #>


    [PoshBot.BotCommand(Permissions = 'view')]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,    

        [parameter(Mandatory, Position = 0)]
        [string] $User
    )

    New-PoshBotCardResponse -Type Normal -Text "slaps $User around a bit with a large trout" -ThumbnailUrl 'http://i.imgur.com/W1Dkemu.jpg'
}