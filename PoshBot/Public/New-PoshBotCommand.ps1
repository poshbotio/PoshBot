
function New-PoshBotCommand {
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        [string]$Name,

        [parameter(Mandatory)]
        [Trigger]$Trigger,

        [string]$Description,

        [string]$HelpText,

        [parameter(Mandatory, ParameterSetName = 'scriptblock')]
        [scriptblock]$ScriptBlock,

        [parameter(Mandatory, ParameterSetName = 'scriptpath')]
        [string]$ScriptPath,

        [parameter(Mandatory, ParameterSetName = 'modulecommand')]
        [string]$Module,

        [parameter(Mandatory, ParameterSetName = 'modulecommand')]
        [string]$CommandName,


        [bool]$Enabled = $true
    )

    $command = [Command]::New()
    $command.Name = $Name
    $command.Trigger = $Trigger

    if ($PSBoundParameters.ContainsKey('Description')) {
        $command.Description = $Description
    }

    if ($PSBoundParameters.ContainsKey('HelpText')) {
        $command.HelpText = $HelpText
    }

    switch ($PSCmdlet.ParameterSetName) {
        'scriptblock' {
            $command.ScriptBlock = $ScriptBlock
        }
        'scriptpath' {
            $command.ScriptPath = $ScriptPath
        }
        'modulecommand' {
            $command.ModuleCommand = "$Module\$CommandName"
        }
    }

    $command.Enabled = $Enabled

    return $command
}
