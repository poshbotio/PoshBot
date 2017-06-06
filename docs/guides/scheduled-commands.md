
# Scheduled Commands

In most cases, commands in PoshBot are entered interactively in a chat application.
There are use cases though were you may want commands to run automatically so you don't have to remember to enter them.
These could be commands that check on external service status and notify the channel of any failures, or spin up/down infrastructure at set times of the day.
Any existing plugin command can be scheduled on a basic reoccurring basis.
The scheduled commands will be executed at a designated time and interval and behave just as though a user entered the command interactively.

> When a scheduled command is executed, it will appear as though it came from the user who scheduled the command and it will be directed to the channel in which it was scheduled.

## Commands

| Command                  | Alias           | Description |
|:-------------------------|:----------------|:------------|
| Get-ScheduledCommand     | getschedule     | Get all scheduled commands (or by Id)
| New-ScheduledCommand     | newschedule     | Create a new scheduled command
| Set-ScheduledCommand     | setschedule     | Modify an existing scheduled command
| Remove-ScheduledCommand  | removeschedule  | Remove a existing scheduled command
| Enable-ScheduledCommand  | enableschedule  | Enable an existing scheduled command
| Disable-ScheduledCommand | disableschedule | Disabled an existing scheduled command

## Permissions

Users must have the `builtin:manage-schedules` permission in order to run these commands.

## Examples

### List all scheduled commands

```
!getschedule
```

### Get a particular scheduled command by Id

```
!getschedule --id 7335e2c7c36b48ea9fd070b7e5085187
```

### Create a new scheduled command to test website health every 5 minutes

```
!newschedule --command 'test-site --url myapp.mydomain.tld` --value 5 --interval minutes
```

### Create a new scheduled command to display the message of the day at 9:00am every day
```
!newschedule --command 'motd` --value 1 --interval days --startafter '9:00am'
```

### Modify an existing scheduled command to run every 4 hours

```
!setschedule --id 7335e2c7c36b48ea9fd070b7e5085187 --value 4 --interval hours
```

### Modify an existing scheduled command to run every hour starting after 8:00am on 2017-07-04

```
!setschedule --id 7335e2c7c36b48ea9fd070b7e5085187 --value 1 --interval hours --startafter '2017-07-04'
```

### Remove a scheduled command

```
!removeschedule --id 7335e2c7c36b48ea9fd070b7e5085187
```

### Enable a scheduled command

```
!enableschedule --id 7335e2c7c36b48ea9fd070b7e5085187
```

### Disable a scheduled command

```
!disableschedule --id 7335e2c7c36b48ea9fd070b7e5085187
```
