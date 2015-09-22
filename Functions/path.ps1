function Test-ValidDriveLetter
{
    [CmdletBinding()]
    param
    (
        [parameter(mandatory                       = $true,
                   position                        = 1,
                   ValueFromPipeline               = $true,
                   ValueFromPipelineByPropertyname = $true)]
        [string]
        $DriveLetter
    )
    process
    {
        $DriveLetter -match '^[a-zA-Z]$'
    }
}
