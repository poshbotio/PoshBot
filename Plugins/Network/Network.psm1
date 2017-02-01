
function Ping {
    <#
    .SYNOPSIS
        Tests a connection to a host
    .EXAMPLE
        !ping --name <www.google.com>
    #>
    [PoshBot.BotCommand(Permissions = 'test-network')]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        [string]$Name
    )

    Write-Output (Test-NetConnection -ComputerName $Name -TraceRoute | Format-List | Out-String)
}

function Dig {
    <#
    .SYNOPSIS
        Perform DNS resolution on a host
    .EXAMPLE
        !dig --name <www.google.com> [--type <A>] [--server <8.8.8.8>]
    #>
    [PoshBot.BotCommand(Permissions = 'test-network')]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        [string]$Name,

        [ValidateSet('A', 'A_AAAA', 'AAAA', 'NS', 'MX', 'MD', 'MF', 'CNAME', 'SOA', 'MB', 'MG', 'MR', 'NULL', 'WKS', 'PTR',
                     'HINFO', 'MINFO', 'TXT', 'RP', 'AFSDB', 'X25', 'ISDN', 'RT', 'SRV', 'DNAME', 'OPT', 'DS', 'RRSIG',
                     'NSEC', 'DNSKEY', 'DHCID', 'NSEC3', 'NSEC3PARAM', 'ANY', 'ALL')]
        [string]$Type = 'A_AAAA',

        [string]$Server
    )

    if ($PSBoundParameters.ContainsKey('Server')) {
        Resolve-DnsName -Name $Name -Type $Type -Server $Server | Format-Table -Autosize | Out-String
    } else {
        Resolve-DnsName -Name $Name -Type $Type | Format-Table -Autosize | Out-String
    }
}
