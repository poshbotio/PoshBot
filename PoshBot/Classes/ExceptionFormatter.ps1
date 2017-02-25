
class ExceptionFormatter {
    static [string]ToJson([System.Management.Automation.ErrorRecord]$Exception) {
        $props = @(
	        @{l = 'CommandName'; e = {$_.InvocationInfo.MyCommand.Name}}
	        @{l = 'Message'; e = {$_.Exception.Message}}
	        @{l = 'Position'; e = {$_.InvocationInfo.PositionMessage}}
	        @{l = 'CategoryInfo'; e = {$_.CategoryInfo.ToString()}}
	        @{l = 'FullyQualifiedErrorId'; e = {$_.FullyQualifiedErrorId}}
        )
        return $Exception | Select-Object -Property $props | ConvertTo-Json
    }
}
