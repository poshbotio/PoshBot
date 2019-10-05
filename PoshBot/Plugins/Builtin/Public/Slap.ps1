function Slap {
    <#
    .SYNOPSIS
        Slap a user with a large trout
    .PARAMETER User
        The user that will be slapped
    .EXAMPLE
        !slap --user jaap

    .EXAMPLE
        !slap jaap foamfinger
    #>
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Mandatory, Position = 0)]
        [string] $User,

        [parameter(Position = 1)]
        [string] $Object
    )
    $objects = @{
        trout = @{
            item = 'large trout'
            thumbnail = 'https://upload.wikimedia.org/wikipedia/commons/1/16/Rainbow_trout_transparent.png'
        }
        finger = @{
            item = 'giant foam finger'
            thumbnail = 'https://images.vexels.com/media/users/3/153013/isolated/preview/517c07f5ff433028345e10b138870119-american-foam-finger-design-element-by-vexels.png'
        }
        keyboard = @{
            item = 'mechanical keyboard'
            thumbnail = 'https://cdn.pixabay.com/photo/2013/07/13/11/50/computer-158770_960_720.png'
        }
        sword = @{
            item = 'foam sword'
            thumbnail = 'https://upload.wikimedia.org/wikipedia/commons/2/2b/Foamswordofrecall.png'
        }
        noodles = @{
            item = 'pile of noodles'
            thumbnail = 'http://pngimg.com/uploads/noodle/noodle_PNG33.png'
        }
    }
    $choice = if ($PSBoundParameters.ContainsKey('Object') -and $objects.ContainsKey($Object)) {
        $objects[$Object]
    }
    else {
        $random = $objects.Keys | Get-Random
        $objects[$random]
    }
    New-PoshBotCardResponse -Type Normal -Text "slaps $User around a bit with a $($choice['item'])" -ThumbnailUrl $choice['thumbnail']
}
