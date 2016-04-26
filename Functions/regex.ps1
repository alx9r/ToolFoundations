Function Test-ValidRegex
{
<#
.SYNOPSIS
Tests for valid regular expression.

.DESCRIPTION
Tests whether the input string parameter Pattern is a valid regular expression using the .NET regex API.  See also http://stackoverflow.com/a/1775017/1404637.

.OUTPUTS
Returns true for a valid regular expression and false otherwise.

.EXAMPLE
    '[0-9]++' | Test-ValidRegex
    # false

Tests an invalid regular expression.  Returns false.

.EXAMPLE
    'bill|ted' | Test-ValidRegex
    # true
Tests a valid regular expression. Returns true.

.LINK
http://stackoverflow.com/a/1775017/1404637
#>
    [CmdletBinding()]
    param
    (
        # The regular expression pattern to test.
        [parameter(ValueFromPipeline=$true,
                   Position=0,
                   Mandatory=$true)]
        [AllowEmptyString()]
        [string]
        $Pattern
    )
    process
    {

        Write-Verbose "Testing pattern `"$Pattern`""
        if (!$Pattern) {return $false}

        try
        {
            [regex]::Match("",$Pattern) | Out-Null
        }
        catch
        {
            Write-Verbose "caught exception"
            return $false
        }

        return $true
    }
}
Function ConvertTo-RegexEscapedString
{
<#
.SYNOPSIS
Converts a string so that all regular expression characters are escaped.

.DESCRIPTION
Escapes a minimal set of characters (\, *, +, ?, |, {, [, (,), ^, $,., #, and white space) by replacing them with their escape codes.  Does this by invoking the .NET API Regex.Escape.

.LINK
http://stackoverflow.com/a/12963199/1404637

.EXAMPLE
    "Yup, just a bunch of `"normal`" characters! 'Cept white space. (and periods...and parentheses)" | ConvertTo-RegexEscapedString
    # "Yup,\ just\ a\ bunch\ of\ `"normal`"\ characters!\ 'Cept\ white\ space\.\ \(and\ periods\.\.\.and\ parentheses\)"

Escapes just the regular expression characters in some prose.
#>
    [CmdletBinding()]
    param
    (
        # The literal text to escape.
        [parameter(ValueFromPipeline=$true,
                   mandatory=$true)]
        [AllowEmptyString()]
        [string]
        $LiteralText
    )
    process
    {
        [regex]::Escape($LiteralText)
    }
}
function ConvertFrom-RegexNamedGroupCapture
{
    [CmdletBinding()]
    param
    (
        [parameter(ValueFromPipeline = $true,
                   ValueFromPipelineByPropertyName = $true,
                   mandatory = $true,
                   Position = 1)]
        [System.Text.RegularExpressions.Match]
        $Match,

        [parameter(ValueFromPipelineByPropertyName = $true,
                   mandatory = $true,
                   Position = 2)]
        [regex]
        $Regex
    )
    process
    {
        if ( -not $Match.Groups[0].Success )
        {
            throw New-Object System.ArgumentException(
                    'Match does not contain any captures.',
                    'Match'
                )
        }
        $h = @{}
        foreach ($name in $Regex.GetGroupNames())
        {
            if ($name -eq 0)
            {
                continue
            }
            $h.$name = $Match.Groups[$name].Value
        }
        return $h
    }
}
