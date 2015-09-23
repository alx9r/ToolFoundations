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

        foreach ($level in ($Path | Split-FilePathFragment))
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
        $Path.Split('\/') | ? { $_ -ne [string]::Empty }
    }
}
function Test-FilePathForTrailingSlash
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
        $Path -match '[\\\/]$'
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
function ConvertTo-FilePathObject
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

        if ( 'Windows','UNC' -notcontains $type )
        {
            Write-Error "Path type of $Path is $type."
            return $false
        }

        if ( $type -eq 'Windows' )
        {
            return New-Object PSObject -Property @{
                OriginalString = $Path
                DriveLetter = $Path | Get-PartOfWindowsPath DriveLetter
                LocalPath = $Path | Get-PartOfWindowsPath Path
                Segments = $Path | Get-PartOfWindowsPath Path | Split-FilePathFragment
                TrailingSlash = $Path | Get-PartOfWindowsPath Path | Test-FilePathForTrailingSlash
            }
        }
        if ( $type -eq 'UNC' )
        {
            return New-Object PSObject -Property @{
                OriginalString = $Path
                DomainName = $Path | Get-PartOfUncPath DomainName
                DriveLetter = $Path | Get-PartOfUncPath DriveLetter
                LocalPath = $Path | Get-PartOfUncPath Path
                Segments = $Path | Get-PartOfUncPath Path | Split-FilePathFragment
                TrailingSlash = $Path | Get-PartOfWindowsPath Path | Test-FilePathForTrailingSlash
            }
        }
    }
}
function Test-ValidFilePathParameters
{
    [CmdletBinding()]
    param
    (
        [parameter(mandatory                       = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [string[]]
        $Segments,

        [parameter(ValueFromPipelineByPropertyName = $true)]
        [string]
        $DriveLetter,

        [parameter(ValueFromPipelineByPropertyName = $true)]
        [string]
        $DomainName,

        [parameter(ValueFromPipelineByPropertyName = $true)]
        [switch]
        $TrailingSlash
    )
    process
    {
        foreach ($segment in $Segments)
        {
            if ( -not ($segment | Test-ValidFileName) )
            {
                Write-Verbose "Segment $segment is not a valid filename."
                return $false
            }
        }

        if ( -not ($DriveLetter | Test-ValidDriveLetter) )
        {
            Write-Verbose "DriveLetter $DriveLetter is not a valid drive letter."
            return $false
        }

        if ( -not ($DomainName | Test-ValidDomainName) )
        {
            Write-Verbose "DomainName $DomainName is not a valid domain name."
            return $false
        }
    }
}
function ConvertTo-FilePathString
{
    [CmdletBinding()]
    param
    (
        [parameter(mandatory                       = $true,
                   position                        = 1,
                   ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('Windows','UNC')]
        [string]
        $FilePathType,

        [parameter(position                        = 2,
                   ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('FileUri','PowerShell')]
        [string]
        $Scheme,

        [parameter(mandatory                       = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [string[]]
        $Segments,

        [parameter(ValueFromPipelineByPropertyName = $true)]
        [string]
        $DriveLetter,

        [parameter(ValueFromPipelineByPropertyName = $true)]
        [string]
        $DomainName,

        [parameter(ValueFromPipelineByPropertyName = $true)]
        [switch]
        $TrailingSlash
    )
    process
    {
        $bp = &(gbpm)

        if
        (
            $FilePathType -eq 'UNC' -and
            -not $bp.DomainName
        )
        {
            Write-Error 'UNC paths require a domain name but none was provided.'
            return $false
        }

        if
        (
            $FilePathType -eq 'Windows' -and
            -not $bp.DriveLetter
        )
        {
            Write-Error 'Windows paths require a drive letter but none was provided.'
            return $false
        }

        if ( $Scheme -eq 'FileUri' )
        {
            $slash = '/'
        }
        else
        {
            $slash = '\'
        }

        if
        (
            $Scheme -eq 'FileUri' -and
            $FilePathType -eq 'Windows'
        )
        {
            $prefix = 'file:///'
        }

        if
        (
            $Scheme -eq 'FileUri' -and
            $FilePathType -eq 'UNC'
        )
        {
            $prefix = 'file:'
        }

        if ( $Scheme -eq 'PowerShell' )
        {
            $prefix = 'FileSystem::'
        }

        if ( $FilePathType -eq 'UNC' )
        {
            return "$prefix$($slash*2)$DomainName$slash$($DriveLetter | ?: "$DriveLetter`$$slash")$($Segments -join $slash)$($TrailingSlash | ?: $slash)"
        }
        if ( $FilePathType -eq 'Windows' )
        {
            return "$prefix$DriveLetter`:$slash$($Segments -join $slash)$($TrailingSlash | ?: $slash)"
        }
    }
}
function ConvertTo-FilePathFormat
{
    [CmdletBinding()]
    param
    (
        [parameter(mandatory                       = $true,
                   position                        = 3,
                   ValueFromPipeline               = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [string]
        $Path,

        [parameter(mandatory                       = $true,
                   position                        = 1,
                   ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('Windows','UNC')]
        [string]
        $FilePathType,

        [parameter(position                        = 2,
                   ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('FileUri','PowerShell')]
        [string]
        $Scheme
    )
    process
    {
        $input = $Path | ConvertTo-FilePathObject

        if
        (
            $FilePathType -eq 'UNC' -and
            -not $input.DomainName
        )
        {
            Write-Error "UNC paths require a domain name but Path $Path does not seem to contain one."
            return $false
        }

        if
        (
            $FilePathType -eq 'Windows' -and
            -not $input.DriveLetter
        )
        {
            Write-Error "Windows paths require a drive letter but Path $Path does not seem to contain one."
            return $false
        }

        $splat = &(gbpm)
        $splat.Remove('Path')
        return $Path | ConvertTo-FilePathObject | ConvertTo-FilePathString @splat
    }
}
