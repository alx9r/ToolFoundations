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
function Test-ValidFileName
{
    [CmdletBinding()]
    param
    (
        [parameter(mandatory=$true,
                   position=1,
                   ValueFromPipeline=$true)]
        [string]
        $FileName
    )
    process
    {
        # https://stackoverflow.com/a/62888/1404637

        # bad characters
        $escapedBadChars = ( ([char[]]'<>:"/\|?*') | ConvertTo-RegexEscapedString ) -join '|'
        if ( $FileName -match "($escapedBadChars)" )
        { 
            return $false 
        }

        # all periods
        if ( $FileName -match '^\.*$' )
        {
            return $false
        }

        # reserved DOS names
        if ( $FileName -match '^(PRN|AUX|NUL|CON|COM[1-9]|LPT[1-9])(\.?|\..*)$' )
        {
            return $false
        }

        # length
        if ($FileName.Length -gt 255 ) 
        { 
            return $false 
        }

        return $true
    }
}