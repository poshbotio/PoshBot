
# Thumbnails for card responses
$thumb = @{
    rutrow  = 'https://raw.githubusercontent.com/poshbotio/PoshBot/master/Media/scooby_doo.jpg'
    don     = 'https://raw.githubusercontent.com/poshbotio/PoshBot/master/Media/don_draper_shrug.jpg'
    warning = 'https://raw.githubusercontent.com/poshbotio/PoshBot/master/Media/yellow_exclamation_point.png'
    error   = 'https://raw.githubusercontent.com/poshbotio/PoshBot/master/Media/exclamation_point_128.png'
    success = 'https://raw.githubusercontent.com/poshbotio/PoshBot/master/Media/green_check_256.png'
}

# Dot source functions
$public  = @( Get-ChildItem -Path $PSScriptRoot/Public/*.ps1 -Recurse -ErrorAction SilentlyContinue )
foreach($function in @($public)) {
    . $function.fullname
}
