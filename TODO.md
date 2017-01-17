    * Support custom response formatting
* Provide better response for failed commands
* Come up with a better way to support optional parameters to scripts
    * Implement logging
    * Enhance !help by filtering on plugins or commands with !help <plugin> | <command>
    * Validate mandatory parameters before calling command and respond back with appropriate error message
* Don't allow a failing command to crash the bot

# Class gotchas
    * Using module statement only looks in modules PSM1 for classes, not dot sourced files.
      This is because it runs at compile time, not run time.
    * Can't access preference variables like $VerbosePreference or $DebugPrefernce inside a PowerShell Class
    * Scope issues with using module statement:
        * from console, using module abc
            * from abc module, using module abc123
        * from console, lost types from abc module

