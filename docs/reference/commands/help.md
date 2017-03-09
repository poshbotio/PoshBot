
# Builtin:Help

## Synopsis

Show details about bot commands.

## Description

The `Help` funtion will list all currently loaded commands for across all plugins.
If the `-Filter` parameter is supplied, it will match against the `FullCommandName`, `Command`, `Plugin`, `Description`, and `Usage` properties.
If only one command that matches the filter is returned, `Help` will show more details about the command.

## Parameters

### -Filter
A string to search for.

## Example
!help [<commandname> | --filter <commandname>]
