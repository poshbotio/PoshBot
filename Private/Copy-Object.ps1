function Copy-Object {
    # http://stackoverflow.com/questions/7468707/deep-copy-a-dictionary-hashtable-in-powershell
    [outputtype([system.object])]
    [cmdletbinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [object[]]$InputObject
    )

    begin {
        $memStream = New-Object -TypeName IO.MemoryStream
        $formatter = New-Object -TypeName Runtime.Serialization.Formatters.Binary.BinaryFormatter
    }

    process {
        foreach ($item in $InputObject) {
            $formatter.Serialize($memStream, $InputObject)
            $memStream.Position=0
            $formatter.Deserialize($memStream)
        }
    }
}
