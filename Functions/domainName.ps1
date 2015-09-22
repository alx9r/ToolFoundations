function Test-ValidDomainName
{
<#
.SYNOPSIS
Tests whether a string is a valid domain name.

.DESCRIPTION
Test-ValidDomainName uses a regular expression match to test whether DomainName is a valid domain name.  The match pattern is the generally-accepted regular expression from http://stackoverflow.com/a/20204811/1404637

.OUTPUTS
Returns true when DomainName is a valid domain name.  Returns false otherwise.

.EXAMPLE
    'as-d.jkl' | Test-ValidDomainName
    # true

as-d.jkl is a valid domain name.

.EXAMPLE
    '-asd.jkl' | Test-ValidDomainName
    # false

Labels cannot start or end with hyphen.

.LINK
http://stackoverflow.com/a/20204811/1404637
#>
    [CmdletBinding()]
    param
    (
        # The domain name to test for validity.
        [Parameter(Mandatory         = $true,
                   Position          = 1,
                   ValueFromPipeline = $true)]
        [string]
        $DomainName
    )
    process
    {
        # http://stackoverflow.com/a/20204811/1404637

        $DomainName -match '(?=^.{4,253}$)(^((?!-)[a-zA-Z0-9-]{1,63}(?<!-)\.)+[a-zA-Z]{2,63}$)'
    }
}
