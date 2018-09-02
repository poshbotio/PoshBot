$request = Get-Content $req -Raw

Out-File -Encoding Ascii -FilePath $outputSbMsg -inputObject $request