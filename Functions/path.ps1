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
function Split-FilePathFragment
{
    [CmdletBinding()]
    param
    (
        [parameter(mandatory                       = $true,
                   position                        = 1,
                   ValueFromPipeline               = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [AllowEmptyString()]
        [string]
        $Path
    )
    process
    {
        $Path.Split('\/')
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
        $PartName,

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

        if ( $PartName -ne 'Path' )
        {
            switch ($PartName ){
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
function Get-PartOfWindowsPath
{
    [CmdletBinding()]
    param
    (
        [parameter(mandatory                       = $true,
                   position                        = 1,
                   ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('DriveLetter','Path')]
        [string]
        $PartName,

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

        switch ($PartName ){
            'DriveLetter' {$mask = '^(?<result>[A-Za-z]*):'}
            'Path'        {$mask = '^[A-Za-z]*:(?<result>.*)'}
        }
        return ([regex]::Match($noprefix,$mask)).Groups['result'].Value
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

        $driveLetter = $noprefix | Get-PartOfWindowsPath DriveLetter
        if ( -not $driveLetter )
        {
            return $false
        }

        $fragment = $noprefix | Get-PartOfWindowsPath Path


        if ( -not ($driveLetter | Test-ValidDriveLetter) )
        {
            Write-Verbose "Path $Path seems like a Windows path but $driveLetter is not a valid drive letter."
            return $false
        }

        if 
        ( 
            $fragment -and
            -not ($fragment | Test-ValidFilePathFragment) 
        )
        {
            Write-Verbose "Path $Path seems like a Windows path but $fragment is not a valid path fragment."
            return $false
        }

        return $true
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
        $isWindows = $Path | Test-ValidWindowsFilePath
        $isUnc = $Path | Test-ValidUncFilePath

        if ( $isWindows -and $isUnc )
        {
            Write-Verbose "$Path could be Windows or UNC."
            return 'ambiguous'
        }
        if ( $isWindows )
        {
            return 'Windows'
        }
        if ( $isUnc )
        {
            return 'UNC'
        }

        return 'Unknown'
    }
}
function ConvertTo-FilePathHashTable
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
        $type = $Path | Get-FilePathType

        if ( $type -notin 'Windows','UNC' )
        {
            Write-Error "Path type of $Path is $type."
            return $false
        }

        if ( $type -eq 'Windows' )
        {
            return @{
                OriginalString = $Path
                DriveLetter = $Path | Get-PartOfWindowsPath DriveLetter
                LocalPath = $Path | Get-PartOfWindowsPath Path
                Segments = $Path | Get-PartOfWindowsPath Path | Split-FilePathFragment
            }
        }
        if ( $type -eq 'UNC' )
        {
            return @{
                OriginalString = $Path
                DomainName = $Path | Get-PartOfUncPath DomainName
                DriveLetter = $Path | Get-PartOfUncPath DriveLetter
                LocalPath = $Path | Get-PartOfUncPath Path
                Segments = $Path | Get-PartOfUncPath Path | Split-FilePathFragment
            }
        }
    }
}
