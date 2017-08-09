
class ExceptionFormatter {

    static [pscustomobject]Summarize([System.Management.Automation.ErrorRecord]$Exception) {
        return [pscustomobject]@{
            CommandName = $Exception.InvocationInfo.MyCommand.Name
            Message = $Exception.Exception.Message
            TargetObject = $Exception.TargetObject
            Position = $Exception.InvocationInfo.PositionMessage
            CategoryInfo = $Exception.CategoryInfo.ToString()
            FullyQualifiedErrorId = $Exception.FullyQualifiedErrorId
        }
    }

    static [string]ToJson([System.Management.Automation.ErrorRecord]$Exception) {
        return ([ExceptionFormatter]::Summarize($Exception) | ConvertTo-Json)
    }
}
