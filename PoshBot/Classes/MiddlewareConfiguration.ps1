
class MiddlewareConfiguration {

    [object] $PreReceiveHooks   = [ordered]@{}
    [object] $PostReceiveHooks  = [ordered]@{}
    [object] $PreExecuteHooks   = [ordered]@{}
    [object] $PostExecuteHooks  = [ordered]@{}
    [object] $PreResponseHooks  = [ordered]@{}
    [object] $PostResponseHooks = [ordered]@{}

    [void] Add([MiddlewareHook]$Hook, [MiddlewareType]$Type) {
        if (-not $this."$($Type.ToString())Hooks".Contains($Hook.Name)) {
            $this."$($Type.ToString())Hooks".Add($Hook.Name, $Hook) > $null
        }
    }

    [void] Remove([MiddlewareHook]$Hook, [MiddlewareType]$Type) {
        if ($this."$($Type.ToString())Hooks".Contains($Hook.Name)) {
            $this."$($Type.ToString())Hooks".Remove($Hook.Name, $Hook) > $null
        }
    }

    [hashtable]ToHash() {
        $hash = @{}
        foreach ($type in [enum]::GetNames([MiddlewareType])) {
            $hash.Add(
                $type,
                $this."$($type)Hooks".GetEnumerator().foreach({$_.Value.ToHash()})
            )
        }
        return $hash
    }

    static [MiddlewareConfiguration] Serialize([hashtable]$DeserializedObject) {
        $mc = [MiddlewareConfiguration]::new()
        foreach ($type in [enum]::GetNames([MiddlewareType])) {
            $DeserializedObject.$type.GetEnumerator().foreach({
                $hook = [MiddlewareHook]::new($_.Name, $_.Path)
                $mc."$($type)Hooks".Add($hook.Name, $hook) > $null
            })
        }
        return $mc
    }
}
