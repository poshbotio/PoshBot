
# Command Approvals

PoshBot includes the ability for certain commands to be marked as requiring approval.
When someone attempts to execute one of these commands, the command will be put into a pending state for a configurable amount of time.
Another user from a designated approval group can then approve or deny the command to be executed.
If no approval or deny command is entered by another user, the pending command will become expired and cancelled.
This workflow is useful for certain commands that are potentially destructive or may generate downtime.
You can also use this to enforce the "four eyes" approach to ensure a second person is aware (and approves) of a certain command to be run.

## Configuration

In order to enable approvals on commands, you populate the `ApprovalConfiguration` section of your bot configuration.
This configuration section has `two` top-level properties

#### ExpireMinutes

This property governs how long a command will be in a pending state (awaiting an approval or deny command) before it expires.
Set this to a reasonable amount of time that you can wait before a command is approved or denied.

#### Commands

This is an array of hashtables stating what commands require approval, what groups are authorized to approve or deny said commands, and whether peer approval is required.

##### Expression
This string is evaluated against the fully qualified command name (`plugin:command:version`) to determine if the command that is about to be executed should require approval first.
**Wildcards are accepted**.

###### Examples

* Require all commands of a given plugin that start with `Remove` to require approval.

```powershell
Expression = 'myplugin:remove*'
```

* Require all versions of a given `Remove-Instance` command to require approval

```powershell
Expression = 'myplugin:remove-instance:*'
```

* Require **ALL** commands of a given plugin to require approval

```powershell
Expression = 'myplugin:*'
```

##### Groups

An array of PoshBot group names that are the designated approvers for commands that match the expression.
Any one user in any of the groups can approve or deny pending commands.

##### PeerApproval

In come cases, the user attempting to execute the command may also be a member of one or more groups that can approve that command.
You may wish to enforce that another user in the approval group(s) (a peer) must approve or deny the command.

## Example Configuration

##### myPoshBotConfig.psd1

```powershell
###
# Other items omitted for brevity
###
ApprovalConfiguration = @{
    ExpireMinutes = 30
    Commands = @(
      @{
        Expression = 'MyPlugin:Deploy-MyApp:*'
        Groups = @('admin', 'MyPlugin-Approvers')
        PeerApproval = $true
      }
      @{
        Expression = '*deploy*'
        Groups = @('Deployment-Approvers')
        PeerApproval = $true
      }
    )
  }
```

## Approving Commands

To approve a command that is pending, a member of the designated approval group(s) must run the `approve` command.
The pending command is given an execution ID which you need to specify when calling `approve`.

### Example
```
!approve -id 1bd05182
```

## Denying Commands

To deny a command that is pending, a member of the designated approval group(s) must run the `deny` command.
The pending command is given an execution ID which you need to specify when calling `deny`.

### Example

```
!deny -id 1bd05182
```

## Listing Pending Commands

To list all commands awaiting approval, use the `pending` command.
This command will include the approval group(s) for the command, when the command execution was attempted, who ran the comamnd, and when the pending command will expire.
