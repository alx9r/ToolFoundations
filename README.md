[![Build status](https://ci.appveyor.com/api/projects/status/q38mor7o20ejxswx?svg=true)](https://ci.appveyor.com/project/alx9r/ToolFoundations)

## ToolFoundations

ToolFoundations is a collection of PowerShell helper functions that I commonly use when writing other Powershell cmdlets in Powershell:

* [`Get-BoundParams`](./Functions/cmdlet.ps1) - a terse way to get the current cmdlet's bound parameters.
* [`Get-CommonParams`](./Functions/cmdlet.ps1) - a terse way to reliably cascade common parameters (like `-Verbose`) from one cmdlet to another
* [`Out-Collection`](./Functions/collection.ps1) - reliably transmit collections through the PowerShell pipeline without loop unrolling
* [`Compare-Object2`](./Functions/compareObject2.ps1) - like `Compare-Object` but accepts Null without throwing and keeps `Passthru` objects separate instead of merging them into a single one-dimensional array
* [`Invoke-Ternary`](./Functions/invoke.ps1) - the `?:` operator with behavior enforced by unit tests
* [`Expand-String`](./Functions/string.ps1) - terse delayed expansion of variables in strings
* [`ConvertTo-RegexEscapedString`](./Functions/regex.ps1) - a pipelinable wrapper for the .NET `Regex.Escape` method
* [`Test-ValidRegex`](./Functions/regex.ps1) - a PowerShell implementation of [the generally-accepted method for validating regex using .NET](https://stackoverflow.com/a/1775017/1404637)
* [`Test-ValidDomainName`](./Functions/domainName.ps1) - a PowerShell implementation of [the generally-accepted method for regex validation of a domain name](http://stackoverflow.com/a/20204811/1404637)
* [`Test-ValidDriveLetter`](./Functions/path.ps1) - regex validation of windows drive letters

## Compatibility

PowerShell Version | Compatible         | Remarks
-------------------|--------------------|--------
2.0                | :white_check_mark: | there are [some PowerShell 2 limitations](https://github.com/alx9r/ToolFoundations/labels/Powershell%202%20Limitation)
3.0                | :grey_question:    | not tested, probably works
4.0                | :white_check_mark: |
5.0                | :white_check_mark: |
