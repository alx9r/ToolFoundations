function Test-ValidGuidString
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position                        = 1,
                   Mandatory                       = $true,
                   ValueFromPipeline               = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [string]
        $GuidString
    )
    process
    {
        $re = '^(\{){0,1}[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}(\}){0,1}$'

        if ( $GuidString -notmatch $re )
        {
            &(Publish-Failure "GuidString $GuidString is not a valid GUID.",'GuidString' ([System.ArgumentException]))
            return $false
        }

        return $true
    }
}
