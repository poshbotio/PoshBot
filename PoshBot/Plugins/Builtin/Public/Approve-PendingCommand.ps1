
function Approve-PendingCommand {
    <#
    .SYNOPSIS
        Approved a command for execution.
    .PARAMETER Id
        The command exeution context ID of a command awaiting approval.
    .EXAMPLE
        !approve -id f087f1fd

        Approve the command with ID f087f1fd. The command will immediately be released and executed.
    #>
    [PoshBot.BotCommand(
        Aliases = ('ack', 'approve', 'approvecommand')
    )]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Mandatory, Position = 0)]
        [string]$Id
    )

    $context = $Bot.DeferredCommandExecutionContexts[$Id]
    if ($context) {
        $callingUserId = $global:PoshBotContext.From
        if (-not $global:PoshBotContext.FromName) {
            $callingUserName = $Bot.RoleManager.ResolveUserIdToUserName($callingUserId)
        } else {
            $callingUserName = $global:PoshBotContext.FromName
        }
        $originalCommandCallingUser = $context.ParsedCommand.From

        if ($callingUserId -ne $originalCommandCallingUser) {
            # Validate calling user is in an approval group for this command
            $approvalGroups = $Bot.Executor.GetApprovalGroups($context)
            $callingUserGroups = $Bot.RoleManager.GetUserGroups($callingUserId).Name
            if ($null -eq $callingUserGroups) { $callingUserGroups = @() }

            $compareParams = @{
                ReferenceObject = $approvalGroups
                DifferenceObject = $callingUserGroups
                PassThru = $true
                IncludeEqual = $true
                ExcludeDifferent = $true
            }
            $inApprovalGroup = (Compare-Object @compareParams).Count -gt 0

            if ($inApprovalGroup) {
                $context.ApprovalState = 2 # [ApprovalState]::Approved
                $context.Approver.Id = $callingUserId
                $context.Approver.Name = $callingUserName
                $Bot.ProcessedDeferredContextQueue.Enqueue($context)

                New-PoshBotCardResponse -Type Normal -Text "Command [$Id] - [$($context.ParsedCommand.CommandString)] approved by [$callingUserName]"
            } else {
                New-PoshBotCardResponse -Type Warning -Text "Sorry. Only someone in approval group(s) [$($approvalGroups -join ', ')] can approve this command."
            }
        } else {
            New-PoshBotCardResponse -Type Warning -Text 'Nice try. Self-approving is not allowed.'
        }
    } else {
        New-PoshBotCardResponse -Type Warning -Text "Unknown approval ID [$Id]"
    }
}
