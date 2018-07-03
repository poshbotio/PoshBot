
class MiddlewareHook {
    [string]$Name
    [scriptblock]$ScriptBlock

    MiddlewareHook([string]$Name, [scriptblock]$ScriptBlock) {
        $this.Name = $Name
        $this.ScriptBlock = $ScriptBlock
    }

    [CommandExecutionContext] Execute([CommandExecutionContext]$Context, [Bot]$Bot) {
        try {
            $params = @{
                ScriptBlock  = $this.ScriptBlock
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
            ScriptBlock = $this.ScriptBlock
        }
    }
}
