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
        [parameter(ValueFromPipeline=$true,
                   Position=0,
                   Mandatory=$true)]
        [AllowEmptyString()]
        [string]
        $Pattern
    )
    process
    {
        #http://stackoverflow.com/a/1775017/1404637

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
