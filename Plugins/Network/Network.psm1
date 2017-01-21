
function Test-Connection {
    <#
    .SYNOPSIS
        Tests a connection to a host
    .EXAMPLE
        !test connection --name www.google.com
    .Role
        Network
    #>
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        [string]$Name
    )

    Write-Output -InputObject (Test-NetConnection -ComputerName $Name -TraceRoute | Format-List)
}

function Dig {
    <#
    .SYNOPSIS
        Perform DNS resolution on a host
    .EXAMPLE
        !dig --host www.google.com
    .EXAMPLE
        !dig --host www.google.com -Type CNAME --server 8.8.8.8
    .Role
        Network
    #>
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
        Resolve-DnsName -Name $Name -Type $Type -Server $Server | Format-Table -Autosize
    } else {
        Resolve-DnsName -Name $Name -Type $Type | Format-Table -Autosize
    }
}
