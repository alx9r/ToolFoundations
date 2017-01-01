function Test-ValidIpAddress
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory         = $true,
                   Position          = 1,
                   ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [string]
        $IpAddress
    )
    process
    {
        # https://stackoverflow.com/q/5284147/1404637

        if ( $IpAddress -notmatch '^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$' )
        {
            &(Publish-Failure "$IpAddress is not a valid IP Address.",'IpAddress' ([System.ArgumentException]))
            return $false
        }
        return $true
    }
}
