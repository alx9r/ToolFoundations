[![Build status](https://ci.appveyor.com/api/projects/status/mc207w55rqmuc13i/branch/master?svg=true&passingText=master%20-%20OK)](https://ci.appveyor.com/project/alx9r/toolfoundations/branch/master)

## ToolFoundations

ToolFoundations is a collection of PowerShell helper functions that I commonly use when writing other Powershell cmdlets in Powershell.

### Cmdlet Parameters and Cascading
Out-of-the-box, accessing and cascading bound and common parameters of a Cmdlet is rather verbose.  To overcome this I use two Cmdlets from ToolFoundations:

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

[The rules that PowerShell uses to decide whether to unroll a collection](https://stackoverflow.com/q/28702588/1404637) in the pipeline [are arcane](https://stackoverflow.com/questions/28702588/in-what-conditions-does-powershell-unroll-items-in-the-pipeline#comment45704300_28707054).  Occasionally it is important to ensure that a collection is not unrolled in the PowerShell pipeline.  This requires selectively wrapping the collection in a sacrificial wrapper.  The tough part is knowing when, in general, to add a sacrificial wrapper.  That requires some trial-and-error to get right.  That trial-and-error [has already been done](https://stackoverflow.com/a/28707054/1404637) and the logic that selectively wraps a collection at just the right times is contained in the [`Out-Collection` Cmdlet](./Functions/collection.ps1).  `Out-Collection` reliably transmits collections through the PowerShell pipeline without loop unrolling

### Better Behaved Common Cmdlets

Some commonly-used Cmdlets exhibiting surprising or undesirable behavior and are re-implemented or wrapped in ToolFoundations:  
* [`Compare-Object2`](./Functions/compareObject2.ps1) - like `Compare-Object` but accepts Null without throwing and keeps `Passthru` objects separate instead of merging them into a single one-dimensional array
* [`Invoke-Ternary`](./Functions/invoke.ps1) - the `?:` operator with behavior enforced by unit tests

### Delayed String Interpolation
Terse delayed string interpolation is [surprisingly unintuitive to implement](https://stackoverflow.com/q/28616274/1404637).  [`Expand-String`](./Functions/string.ps1) is an implementation of terse delayed expansion of variables in strings.

### Pipelineable Regex Cmdlets
.NET has great Regex support.  ToolFoundations contains a couple Cmdlets that wrap that API in PowerShell-friendly pipelineable form:
* [`ConvertTo-RegexEscapedString`](./Functions/regex.ps1) - a pipelinable wrapper for the .NET `Regex.Escape` method
* [`Test-ValidRegex`](./Functions/regex.ps1) - a PowerShell implementation of [the generally-accepted method for validating regex using .NET](https://stackoverflow.com/a/1775017/1404637)

### Path Validation
PowerShell parameters are often path strings like file names, drive letters, and domain names.  These have to have certain properties to be valid.  ToolFoundations includes the following functions that test for validity:

* [`Test-ValidDomainName`](./Functions/domainName.ps1) - a PowerShell implementation of [the generally-accepted method for regex validation of a domain name](http://stackoverflow.com/a/20204811/1404637)
* [`Test-ValidDriveLetter`](./Functions/filePath.ps1) - regex validation of windows drive letters
* [`Test-ValidFileName`](./Functions/filePath.ps1) - regex validation of windows file names
* [`Test-ValidPathFragment`](./Functions/filePath.ps1) - validation of path fragments
* [`Test-ValidWindowsFilePath`](./Functions/filePath.ps1) - validation of Windows file paths
* [`Test-ValidUncFilePath`](./Functions/filePath.ps1) - validation of UNC file paths

### Path Conversion and Manipulation
Different tools and APIs produce and accept a rather wide variety of file path formats.  ToolFoundations i[ncludes a variety of Cmdlets](./Functions/filePath.ps1) to manipulate file paths and change their format.  The most powerful Cmdlets for this are `ConvertTo-FilePathObject`, `ConvertTo-FilePathString`, and `ConvertTo-FilePathFormat`.  With those, you can do one line conversions like this:

````PowerShell
PS c:\> '\\domain.name\c$\local\path' | ConvertTo-FilePathFormat
c:\local\path
````

...and this:

````PowerShell
PS c:\> '\\domain.name\c$\local\path' | ConvertTo-FilePathFormat Windows PowerShell
FileSystem::c:\local\path
````

You can also manipulate paths by simply changing properties on an object:

````PowerShell
PS c:\> $object = 'c:\local\path' | ConvertTo-FilePathObject
PS c:\> $object.Segments += 'file.txt'
PS c:\> $object | ConvertTo-FilePathString Windows PowerShell
FileSystem::c:\local\path\file.txt
````

## Compatibility

PowerShell Version | Compatible         | Remarks
-------------------|--------------------|--------
2.0                | :white_check_mark: | there are [some PowerShell 2 limitations](https://github.com/alx9r/ToolFoundations/labels/Powershell%202%20Limitation)
3.0                | :grey_question:    | not tested, probably works
4.0                | :white_check_mark: |
5.0                | :white_check_mark: |
