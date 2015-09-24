[![Build status](https://ci.appveyor.com/api/projects/status/q38mor7o20ejxswx?svg=true)](https://ci.appveyor.com/project/alx9r/ToolFoundations)

## ToolFoundations

ToolFoundations is a collection of PowerShell helper functions that I commonly use when writing other Powershell cmdlets in Powershell.

### Cmdlet Parameters and Cascading
Out-of-the-box, accessing and cascading bound and common parameters of a Cmdlet is rather verbose.  To overcome this I use two Cmdlets:

* [`Get-BoundParams`](./Functions/cmdlet.ps1) - a terse way to get the current cmdlet's bound parameters.
* [`Get-CommonParams`](./Functions/cmdlet.ps1) - a terse way to reliably cascade common parameters (like `-Verbose`) from one cmdlet to another

There are three prominent use-cases for these.  First, cascading common parameters like `-Verbose` is easily achieved like this:

````Powershell
function Some-Function {
	...
	process
	{
		$cp = &(gcp)
		# $cp now contains a hashtable of common parameters like -Verbose
		...
		# Here Do-Something is invoked with the same common parameters as the current script.
		Do-Something @cp 
	}
	...
````

Similarly, `Get-BoundParameters` can be used to cascade parameters from one Cmdlet to another with a compatible type signature:

````PowerShell
		$bp = &(gbpm)
		Some-OtherFunction @bp
````

Third, the alias `gbpm` is a terse way to determine whether an optional parameter was bound:

````PowerShell
		if ( 'SomeParameter' -in (&(gbpm)).Keys )
		{
			...
		}
````
### Pipeline Unrolling

[`Out-Collection`](./Functions/collection.ps1) reliably transmits collections through the PowerShell pipeline without loop unrolling

### Better Behaved Common Cmdlets
* [`Compare-Object2`](./Functions/compareObject2.ps1) - like `Compare-Object` but accepts Null without throwing and keeps `Passthru` objects separate instead of merging them into a single one-dimensional array
* [`Invoke-Ternary`](./Functions/invoke.ps1) - the `?:` operator with behavior enforced by unit tests

### Delayed String Interpolation
* [`Expand-String`](./Functions/string.ps1) - terse delayed expansion of variables in strings

### Pipelineable Regex Cmdlets 
* [`ConvertTo-RegexEscapedString`](./Functions/regex.ps1) - a pipelinable wrapper for the .NET `Regex.Escape` method
* [`Test-ValidRegex`](./Functions/regex.ps1) - a PowerShell implementation of [the generally-accepted method for validating regex using .NET](https://stackoverflow.com/a/1775017/1404637)

### File Path Conversion and Validation
* [`Test-ValidDomainName`](./Functions/domainName.ps1) - a PowerShell implementation of [the generally-accepted method for regex validation of a domain name](http://stackoverflow.com/a/20204811/1404637)
* [`Test-ValidDriveLetter`](./Functions/path.ps1) - regex validation of windows drive letters
* [`Test-ValidFileName`](./Functions/path.ps1) - regex validation of windows file names
* [`Test-ValidPathFragment`](./Functions/path.ps1) - validation of path fragments

## Compatibility

PowerShell Version | Compatible         | Remarks
-------------------|--------------------|--------
2.0                | :white_check_mark: | there are [some PowerShell 2 limitations](https://github.com/alx9r/ToolFoundations/labels/Powershell%202%20Limitation)
3.0                | :grey_question:    | not tested, probably works
4.0                | :white_check_mark: |
5.0                | :white_check_mark: |
