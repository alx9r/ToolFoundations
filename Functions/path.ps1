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
function Test-ValidFilePathFragment
{
    [CmdletBinding()]
    param
    (
        [parameter(mandatory                       = $true,
                   position                        = 1,
                   ValueFromPipeline               = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [string]
        $PathFragment
    )
    process
    {
        # test for mixed slashes
        if
        (
            $PathFragment -match '\\' -and
            $PathFragment -match '\/'
        )
        {
            Write-Verbose "Path fragment $PathFragment contains both forward and backslashes."
            return $false
        }

        foreach ($level in $PathFragment.Split('\/'))
        {
            if ( -not ($level | Test-ValidFileName) )
            {
                Write-Verbose "Path fragment $PathFragment contains level $level that is an invalid filename."
                return $false
            }
        }

        return $true
    }
}
function ConvertTo-FilePathWithoutPrefix
{
    [CmdletBinding()]
    param
    (
        [parameter(mandatory                       = $true,
                   position                        = 1,
                   ValueFromPipeline               = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [string]
        $Path
    )
    process
    {
        # PowerShell Windows Path
        $masks = '^FileSystem::(.*)',
                 '^MicroSoft.PowerShell.Core\\FileSystem::(.*)',
                 '^file:///([A-Za-z]:.*)',
                 '^file:(?!///)(//.*)'

        foreach ( $mask in $masks )
        {
            if ( $Path -match $mask )
            {
                return $Path -replace $mask,'$1'
            }
        }

        return $Path
    }
}
function Get-FilePathType
{
    [CmdletBinding()]
    param
    (
        [parameter(mandatory                       = $true,
                   position                        = 1,
                   ValueFromPipeline               = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [string]
        $Path
    )
    process
    {
        $noprefix = $Path | ConvertTo-FilePathWithoutPrefix
        if ( $noprefix -match '^[A-Za-z]:')
        {
            return 'windows'
        }
        if ( $noprefix -match '^\\\\[A-Za-z]')
        {
            return 'UNC'
        }

        Write-Error "Could not identify type of Path $Path"
        return $false
    }
}