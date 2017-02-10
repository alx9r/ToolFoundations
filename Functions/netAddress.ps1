function Test-ValidNetAddress
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory         = $true,
                   Position          = 1,
                   ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [string]
        $Address
    )
    process
    {
        if
        (
            ( $Address | Test-ValidIpAddress ) -or
            ( $Address | Test-ValidDomainName )
        )
        {
            return $true
        }

        &(Publish-Failure "$Address is not a valid IP or DNS address.",'Address' ([System.ArgumentException]))
        return $false
    }
}
