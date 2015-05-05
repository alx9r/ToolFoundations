Set-Alias xs Expand-String
<#
.SYNOPSIS
Creates a script block for string expansion.

.DESCRIPTION
Creates a script block that, when invoked expands the local variables in the caller's context.

http://stackoverflow.com/a/28628460/1404637

Use the alias "xs" to make calls to Expand-String terse.

.OUTPUTS
The script block that, when invoked, will expand String using the caller's context.
.EXAMPLE
$MyString = 'The $animal says $sound.'
...
$animal = 'pig'
...
$sound = 'oink'

&($MyString | Expand-String)
&(Expand-String $MyString)

$animal and $sound aren't expanded until the last two lines.  This allows you to set up a string with variables to be expanded and delay expansion until the variables have the values you want.

.LINK
http://stackoverflow.com/a/28628460/1404637
#>
function Expand-String
{
    [CmdletBinding()]
    param
    (

        #The string containing variables that will be expanded.
        [parameter(ValueFromPipeline=$true,
                   Position=0)]
        [string]
        $String=$null
    )
    process
    {
        if (!$String) {$(throw "String is mandatory.")}
        $escapedString = $String -replace '"','`"'
        $code = "`$ExecutionContext.InvokeCommand.ExpandString(`"$escapedString`")"
        [scriptblock]::create($code)
    }
}

Export-ModuleMember -Function * -Alias *
