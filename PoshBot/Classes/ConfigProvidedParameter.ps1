
class ConfigProvidedParameter {
    [PoshBot.FromConfig]$Metadata
    [System.Management.Automation.ParameterMetadata]$Parameter

    ConfigProvidedParameter([PoshBot.FromConfig]$Meta, [System.Management.Automation.ParameterMetadata]$Param) {
        $this.Metadata = $Meta
        $this.Parameter = $param
    }
}
