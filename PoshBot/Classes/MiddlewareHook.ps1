
class MiddlewareHook {
    [string]$Name
    [string]$Path

    MiddlewareHook([string]$Name, [string]$Path) {
        $this.Name = $Name
        $this.Path = $Path
    }

    [CommandExecutionContext] Execute([CommandExecutionContext]$Context, [Bot]$Bot) {
        try {
            $fileContent = Get-Content -Path $this.Path -Raw
            $scriptBlock = [scriptblock]::Create($fileContent)
            $params = @{
                scriptblock  = $scriptBlock
                ArgumentList = @($Context, $Bot)
                ErrorAction  = 'Stop'
            }
            $Context = Invoke-Command @params
        } catch {
            throw $_
        }
        return $Context
    }

    [hashtable]ToHash() {
        return @{
            Name = $this.Name
            Path = $this.Path
        }
    }
}
