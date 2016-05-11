function Test-NumericType
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 1,
                   Mandatory = $true,
                   ValueFromPipeline = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [System.Type]
        $Type
    )
    process
    {
        if ( $Type -eq [string] )
        {
            return $false
        }
        try
        {
            [System.Convert]::ChangeType(1,$Type) | Out-Null
        }
        catch [System.InvalidCastException]
        {
            return $false
        }
        return $true
    }
}
