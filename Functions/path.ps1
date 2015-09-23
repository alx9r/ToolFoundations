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
function HasMixedSlashes
{
    [CmdletBinding()]
    param
    (
        [parameter(mandatory                       = $true,
                   position                        = 1,
                   ValueFromPipeline               = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [string]
        $InputString
    )
    process
    {
        $InputString -match '\\' -and $InputString -match '\/'
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
        $Path
    )
    process
    {
        if ( $Path | HasMixedSlashes )
        {
            Write-Verbose "Path fragment $Path contains both forward and backslashes."
            return $false
        }

        foreach ($level in $Path.Split('\/'))
        {
            if ( -not ($level | Test-ValidFileName) )
            {
                Write-Verbose "Path fragment $Path contains level $level that is an invalid filename."
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
function Get-PartOfUncPath
{
    [CmdletBinding()]
    param
    (
        [parameter(mandatory                       = $true,
                   position                        = 1,
                   ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('DomainName','DriveLetter','Path')]
        [string]
        $ComponentName,

        [parameter(mandatory                       = $true,
                   position                        = 2,
                   ValueFromPipeline               = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [string]
        $Path
    )
    process
    {
        $noprefix = $Path | ConvertTo-FilePathWithoutPrefix

        if ( $ComponentName -ne 'Path' )
        {
            switch ($ComponentName ){
                'DomainName'  {$mask = '^(\\\\|\/\/)(?<result>[^\\\/]*)'}
                'DriveLetter' {$mask = '^(\\\\|\/\/)[^\\\/]*[\\\/](?<result>[^\\\/\$]*)\$([\\\/]|$)'}
            }
            return ([regex]::Match($noprefix,$mask)).Groups['result'].Value
        }

        if ( $Path | Get-PartOfUncPath DriveLetter )
        {
            $mask = '^(\\\\|\/\/)[^\\\/]*[\\\/][^\\\/\$]*\$(?<result>([\\\/]|$).*)'
        }
        else
        {
            $mask = '^(\\\\|\/\/)[^\\\/]*(?<result>[\\\/].*)'
        }

        return ([regex]::Match($noprefix,$mask)).Groups['result'].Value
    }
}
function Test-ValidUncFilePath
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
        if ( $Path | HasMixedSlashes )
        {
            Write-Verbose "Path $Path has mixed slashes."
            return $false
        }

        $noprefix = $Path | ConvertTo-FilePathWithoutPrefix

        ### domain name

        $domainName = $Path | Get-PartOfUncPath DomainName

        if ( -not $domainName )
        {
            return $false
        }
        if ( -not ($domainName | Test-ValidDomainName ) )
        {
            Write-Verbose "Seems like a UNC path, but $domainName is not a valid domain name."
            return $false
        }


        ### drive letter

        $driveLetter = $Path | Get-PartOfUncPath DriveLetter

        if
        (
            $driveLetter -and
            -not ($driveLetter | Test-ValidDriveLetter)
        )
        {
            Write-Verbose "Seems like a UNC path administrative share, but $driveLetter is not a valid drive letter."
            return $false
        }

        ### path fragment

        $fragment = $Path | Get-PartOfUncPath Path

        if
        (
            $fragment -and
            -not ($fragment | Test-ValidFilePathFragment)
        )
        {
            Write-Verbose "Seems like a UNC path, but $fragment is not a valid path fragment."
            return $false
        }

        return $true
    }
}
function Test-ValidWindowsFilePath
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
        if ( $Path | HasMixedSlashes )
        {
            Write-Verbose "Path $Path has mixed slashes."
            return $false
        }

        $noprefix = $Path | ConvertTo-FilePathWithoutPrefix

        $driveLetter,$fragment = $noprefix -split ':',2
        if ( -not $driveLetter )
        {
            return $false
        }

        if ( -not ($driveLetter | Test-ValidDriveLetter) )
        {
            Write-Verbose "Path $Path seems like a Windows path but $driveLetter is not a valid drive letter."
            return $false
        }

        if ( -not ($fragment | Test-ValidFilePathFragment) )
        {
            Write-Verbose "Path $Path seems like a Windows path but $fragment is not a valid path fragment."
            return $false
        }

        return $true
    }
}
