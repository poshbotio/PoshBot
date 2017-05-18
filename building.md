
# Building PoshBot

The PoshBot repository has various tasks defined in [psake](https://github.com/psake/psake). These tasks can be executed via the `build.ps1` script and passing in the task name you wish to execute.

## Tasks

Task name   | Description
------------|-------------------------
Analyze     | Run PSScriptAnalyzer rules
Pester      | Run Pester tests
Test        | Run both the Analyze and Pester tasks
Build       | Compile PS source files

### Analyze

Run [PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer) rules on the module.

This task will first _compile_ the source files into the complete module under the `out` folder in the root of the repository and then run Script Analyzer rules against it.

```powershell
.\build.ps1 -Task Analyze
```

### Pester

Run Pester tests against the module.

This task will first _compile_ the source files into the complete module under the `out` folder in the root of the repository and then run a set of Pester tests to validate functionality.

```powershell
.\build.ps1 -Task Pester
```

### Test

Run both the Analyze and Pester tasks

```powershell
.\build.ps1 -Task Test
```

### Build

Build the source files into a usable module. The files under the `PoshBot` subfolder *will not* run as a PowerShell module by itself. The module must be *built* first. This task will produce a usable module in a folder called `out` in the root of the repository.

```powershell
.\build.ps1 -Task Build
```
