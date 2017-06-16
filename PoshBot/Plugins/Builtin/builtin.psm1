
# Thumbnails for card responses
$thumb = @{
    rutrow = 'http://images4.fanpop.com/image/photos/17000000/Scooby-Doo-Where-Are-You-The-Original-Intro-scooby-doo-17020515-500-375.jpg'
    don = 'http://p1cdn05.thewrap.com/images/2015/06/don-draper-shrug.jpg'
    warning = 'http://hairmomentum.com/wp-content/uploads/2016/07/warning.png'
    error = 'https://cdn0.iconfinder.com/data/icons/shift-free/32/Error-128.png'
    success = 'https://www.streamsports.com/images/icon_green_check_256.png'
}

# Dot source functions
$public  = @( Get-ChildItem -Path $PSScriptRoot/Public/*.ps1 -Recurse -ErrorAction SilentlyContinue )
foreach($function in @($public)) {
    . $function.fullname
}
