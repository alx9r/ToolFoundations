Set-Alias CoerceTo-FilePathString Invoke-CoercionToFilePathString
Set-Alias CoerceTo-FilePathObject Invoke-CoercionToFilePathObject
function Test-ValidDriveLetter
{
<#
.SYNOPSIS
Test drive letter for validity.

.DESCRIPTION
Test-ValidDriveLetter tests DriveLetter for validity.  It does the following:

    * tests for a length once character long
    * tests for a letter A to Z upper or lower case

.OUTPUTS
True if DriveLetter is valid.  False otherwise.
#>
    [CmdletBinding()]
    param
    (
        # The drive letter to test for validity.
        [parameter(mandatory                       = $true,
                   position                        = 1,
                   ValueFromPipeline               = $true,
                   ValueFromPipelineByPropertyname = $true)]
        [AllowEmptyString()]
        [string]
        $DriveLetter
    )
    process
    {
        if ($DriveLetter -notmatch '^[a-zA-Z]$')
        {
            &(Publish-Failure "$DriveLetter is not a valid drive letter.",'DriveLetter' ([System.ArgumentException]))
            return $false
        }
        return $true
    }
}
function Test-ValidFileName
{
<#
.SYNOPSIS
Test file name for validity.

.DESCRIPTION
Test-ValidFileName tests FileName for validity based on the generally-accepted method at https://stackoverflow.com/a/62888/1404637.  Test-ValidFileName does the following:

    * checks for any characters disallowed by windows
    * checks for a filename that is all periods
    * checks for reserved DOS names
    * checks length

.OUTPUTS
True if FileName is known valid.  False otherwise.

.LINK
    https://stackoverflow.com/a/62888/1404637
    Publish-Failure
#>
    [CmdletBinding()]
    param
    (
        # The file name to test for validity.
        [parameter(mandatory=$true,
                   position=1,
                   ValueFromPipeline=$true)]
        [AllowEmptyString()]
        [string]
        $FileName
    )
    process
    {
        # https://stackoverflow.com/a/62888/1404637

        # empty string
        if ( $FileName -eq [string]::Empty )
        {
            &(Publish-Failure 'Filename is an empty string.','FileName' ([System.ArgumentException]))
            return $false
        }

        # bad characters
        $badChars = [char[]]'<>:"/\|?*'
        $escapedBadChars = ( $badChars | ConvertTo-RegexEscapedString ) -join '|'
        if ( $FileName -match "($escapedBadChars)" )
        {
            &(Publish-Failure "FileName $FileName contains one of these bad characters: $badChars",'FileName' ([System.ArgumentException]))
            return $false
        }

        # all periods
        if ( $FileName -match '^\.*$' )
        {
            &(Publish-Failure "FileName $FileName is all periods.",'FileName' ([System.ArgumentException]))
            return $false
        }

        # reserved DOS names
        $regex = '^(PRN|AUX|NUL|CON|COM[1-9]|LPT[1-9])(\.?|\..*)$'
        if ( $FileName -match $regex )
        {
            &(Publish-Failure "FileName $FileName contains a reserved DOS name.  It matches this regular expression: $regex",'FileName' ([System.ArgumentException]))
            return $false
        }

        # length
        if ($FileName.Length -gt 255 )
        {
            &(Publish-Failure "FileName $FileName is longer than 255 characters.",'FileName' ([System.ArgumentException]))
            return $false
        }

        return $true
    }
}
function Test-FilePathForMixedSlashes
{
<#
.SYNOPSIS
Test path for mixed slashes.

.DESCRIPTION
Test-FilePathForMixedSlashes test whether Path has a mix of forward and backward slashes.

.OUTPUTS
True if Path contains both backward and forward slashes.  False otherwise.
#>
    [CmdletBinding()]
    param
    (
        # The path string to test for mixed slashes.
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
        $Path -match '\\' -and $Path -match '\/'
    }
}
function Test-ValidFilePathFragment
{
<#
.SYNOPSIS
Tests whether a file path fragment is valid.

.DESCRIPTION
Test-ValidFilePathFragment test whether a file path fragment is valid.  It does the following:

    * returns false for mixed slashes
    * extracts and tests path segments for validity

.OUTPUTS
True if Path is known-valid.  False otherwise.
#>
    [CmdletBinding()]
    param
    (
        # The path string to test for validity.
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
        if ( $Path | Test-FilePathForMixedSlashes )
        {
            Write-Verbose "Path fragment $Path contains both forward and backslashes."
            return $false
        }

        $segmentIndex = 0
        foreach ($level in ($Path | Split-FilePathFragment))
        {
            if ($level -ne '..')
            {
                $segmentIndex++
            }
            else
            {
                $segmentIndex--
            }

            if ($segmentIndex -lt 0)
            {
                Write-Verbose "Path fragment $Path contains too many `"..`""
                return $false
            }

            if
            (
               '.','..' -notcontains $level -and
                -not ($level | Test-ValidFileName)
            )
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
<#
.SYNOPSIS
Split a file path fragment on its slashes.

.DESCRIPTION
Split-FilePathFragment splits Path on its slashes.

.OUTPUTS
A list of only the segments of Path.
#>
    [CmdletBinding()]
    param
    (
        # The path to split.
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
        Out-Collection @( $Path.Split('\/') | ? { $_ -ne [string]::Empty } )
    }
}
function Test-FilePathForTrailingSlash
{
<#
.SYNOPSIS
Tests a path for a trailing slash.

.DESCRIPTION
Test-FilePathForTrailingSlash test Path for the presense of a trailing backward or forward slash.

.OUTPUTS
True if Path has a trailing slash.  False otherwise.
#>
    [CmdletBinding()]
    param
    (
        # The path to test for a trailing slash.
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
<#
.SYNOPSIS
Strips prefixes from file paths.

.DESCRIPTION
ConvertTo-FilePathWithoutPrefix strips some known prefixes from file path strings.  The prefixes that can be stripped are as follows:

    * FileSystem::
    * Microsoft.PowerShell.Core\FileSystem::
    * file://
    * file:///

.OUTPUTS
Path with prefix removed.

#>
    [CmdletBinding()]
    param
    (
        # The path to strip the prefix from.
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
        $masks = '^FileSystem::(.*)',
                 '^MicroSoft.PowerShell.Core\\FileSystem::(.*)',
                 '^file:///([A-Za-z]:.*)',
                 '^file:(?!///)(//.*)'

        $match = $masks |
            ? { $Path -match $_ } |
            Select -First 1

        if ( $match )
        {
            return $Path -replace $match,'$1'
        }

        return $Path
    }
}
function Get-FilePathScheme
{
<#
.SYNOPSIS
Determine whether a file path uses a plain, PowerShell, or URI "scheme".

.DESCRIPTION
Get-FilePathScheme detects whether Path uses a plain, PowerShell, LongPowerShell, or FileUri "scheme" and outputs a string accordingly. Get-FilePathScheme accepts formatting "schemes" as follows:

    Scheme         | Examples
    ---------------+---------------------
    plain          | c:\local\path,
                   | \\domain.name\c$\local\path
    FileUri        | file:///c:/local/path
                   | file://domain.name/c$/local/path
    PowerShell     | FileSystem::c:\local\path
                   | FileSystem::\\domain.name\c$\local\path
    LongPowerShell | Microsoft.PowerShell.Core\FileSystem::c:\local\path

.OUTPUTS
"plain", "FileUri", "PowerShell", or "LongPowerShell" if the "scheme" is identified.  "unknown" otherwise.
#>
    [CmdletBinding()]
    param
    (
        # The path whose scheme to detect.
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
        $masks = @{
            plain          = '^[A-Za-z]:',
                             '^\\\\[A-Za-z0-9]'
            PowerShell     = '^FileSystem::(.*)'
            LongPowerShell = '^MicroSoft.PowerShell.Core\\FileSystem::(.*)'
            FileUri        = '^file:///([A-Za-z]:.*)',
                             '^file:(?!///)(//.*)'
        }


        $match = $masks.Keys |
            ? {
                $masks.$_ | ? { $Path -match $_ }
            } |
            Select -First 1

        if ( $match )
        {
            return $match
        }

        return 'unknown'
    }
}
function Get-PartOfUncPath
{
<#
.SYNOPSIS
Extract part of a Unc path.

.DESCRIPTION
Get-PartOfUncPath extracts the part of Path indicated by PartName.

.OUTPUTS
A string representation of path part extracted from Path.  Empty string otherwise.

#>
    [CmdletBinding()]
    param
    (
        # The name of the part of the path to extract from Path.
        [parameter(mandatory                       = $true,
                   position                        = 1,
                   ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('DomainName','DriveLetter','LocalPath')]
        [string]
        $PartName,

        # The string path to extract the part from.
        [parameter(mandatory                       = $true,
                   position                        = 2,
                   ValueFromPipeline               = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [AllowEmptyString()]
        [string]
        $Path
    )
    process
    {
        $noprefix = $Path | ConvertTo-FilePathWithoutPrefix

        if ( $PartName -ne 'LocalPath' )
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
<#
.SYNOPSIS
Test whether a string is a valid UNC file path.

.DESCRIPTION
Test-ValidUncFilePath determines whether Path is a valid Windows file path.  It does the following:

    * returns false for mixed slashes
    * extracts and tests domains names for validity
    * extracts and tests drive letters for validity
    * extracts and tests path segments for validity

.OUTPUTS
True if Path is known-valid.  False otherwise.
#>
    [CmdletBinding()]
    param
    (
        # The path string to test for validity.
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
        if ( $Path | Test-FilePathForMixedSlashes )
        {
            Write-Verbose "Path $Path has mixed slashes."
            return $false
        }

        $noprefix = $Path | ConvertTo-FilePathWithoutPrefix

        ### domain name

        $domainName = $Path | Get-PartOfUncPath DomainName

        if ( -not $domainName )
        {
            &(Publish-Failure 'Cannot be a UNC path, no domain name was found.','Path' ([System.ArgumentException]))
            return $false
        }
        if ( -not ($domainName | Test-ValidDomainName ) )
        {
            &(Publish-Failure "Seems like a UNC path, but $domainName is not a valid domain name.",'Path' ([System.ArgumentException]))
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
            &(Publish-Failure "Seems like a UNC path administrative share, but $driveLetter is not a valid drive letter.",'Path' ([System.ArgumentException]))
            return $false
        }

        ### path fragment

        $fragment = $Path | Get-PartOfUncPath LocalPath

        if
        (
            $fragment -and
            -not ($fragment | Test-ValidFilePathFragment)
        )
        {
            &(Publish-Failure "Seems like a UNC path, but $fragment is not a valid path fragment.",'Path' ([System.ArgumentException]))
            return $false
        }

        return $true
    }
}
function Get-PartOfWindowsPath
{
<#
.SYNOPSIS
Extract part of a Windows path.

.DESCRIPTION
Get-PartOfWindowsPath extracts the part of Path indicated by PartName.

.OUTPUTS
A string representation of path part extracted from Path.  Empty string otherwise.

#>
    [CmdletBinding()]
    param
    (
        # The name of the part of the path to extract from Path.
        [parameter(mandatory                       = $true,
                   position                        = 1,
                   ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('DriveLetter','LocalPath')]
        [string]
        $PartName,

        # The string path to extract the part from.
        [parameter(mandatory                       = $true,
                   position                        = 2,
                   ValueFromPipeline               = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [AllowEmptyString()]
        [string]
        $Path
    )
    process
    {
        $noprefix = $Path | ConvertTo-FilePathWithoutPrefix

        switch ($PartName ){
            'DriveLetter' {$mask = '^(?<result>[A-Za-z]*):'}
            'LocalPath'        {$mask = '^[A-Za-z]*:(?<result>.*)'}
        }
        return ([regex]::Match($noprefix,$mask)).Groups['result'].Value
    }
}
function Test-ValidWindowsFilePath
{
<#
.SYNOPSIS
Test whether a string is a valid Windows file path.

.DESCRIPTION
Test-ValidWindowsFilePath determines whether Path is a valid Windows file path.  It does the following:

    * returns false mixed slashes
    * returns false if it's longer than permitted
    * extracts and tests drive letters for validity
    * extracts and tests path segments for validity

.OUTPUTS
True if Path is known-valid.  False otherwise.
#>
    [CmdletBinding()]
    param
    (
        # The path string to test for validity.
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
        if ( $Path | Test-FilePathForMixedSlashes )
        {
            &(Publish-Failure "Path $Path has mixed slashes.",'Path' ([System.ArgumentException]))
            return $false
        }

        $noprefix = $Path | ConvertTo-FilePathWithoutPrefix

        if ( $noprefix.Length -gt 255 )
        {
            &(Publish-Failure "Path is $($noprefix.Length) characters long.  Max allowed: 260",'Path' ([System.ArgumentException]))
            return $false
        }

        $driveLetter = $noprefix | Get-PartOfWindowsPath DriveLetter
        if ( -not $driveLetter )
        {
            return $false
        }

        $fragment = $noprefix | Get-PartOfWindowsPath LocalPath


        if ( -not ($driveLetter | Test-ValidDriveLetter) )
        {
            &(Publish-Failure "Path $Path seems like a Windows path but $driveLetter is not a valid drive letter.",'Path' ([System.ArgumentException]))
            return $false
        }

        if
        (
            $fragment -and
            -not ($fragment | Test-ValidFilePathFragment)
        )
        {
            &(Publish-Failure "Path $Path seems like a Windows path but $fragment is not a valid path fragment.",'Path' ([System.ArgumentException]))
            return $false
        }

        return $true
    }
}
function Test-ValidFilePath
{
<#
.SYNOPSIS
Test whether a string is a valid file path.

.DESCRIPTION
Test-ValidFilePath determines whether Path is a valid Windows or UNC file path.  It invokes Test-ValidUncFilePath and Test-ValidWindowsFilePath.

.OUTPUTS
True if Path is known-valid.  False otherwise.
#>
    [CmdletBinding()]
    param
    (
        # The path string to test for validity.
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
        if ( $Path | Test-ValidUncFilePath -ErrorAction SilentlyContinue )
        {
            return $true
        }
        if ( $Path | Test-ValidWindowsFilePath -ErrorAction SilentlyContinue )
        {
            return $true
        }

        &(Publish-Failure "$Path is not a known-valid file path.",'Path' ([System.ArgumentException]))
        return $false
    }
}
function Get-FilePathType
{
<#
.SYNOPSIS
Determine whether a file path is Windows or UNC.

.DESCRIPTION
Get-FilePathType detects whether Path is a Windows or UNC path and outputs a string accordingly.

.OUTPUTS
"UNC" if Path is a UNC path. "Windows" if Path is a Windows path.  "ambiguous" or "unknown" otherwise.
#>
    [CmdletBinding()]
    param
    (
        # The path whose type to determine.
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
        $isWindows = $Path | Test-ValidWindowsFilePath -ErrorAction Continue
        $isUnc = $Path | Test-ValidUncFilePath -ErrorAction Continue

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

        return 'unknown'
    }
}
function Get-FilePathDelimiter
{
<#
.SYNOPSIS
Detect the delimiter used to separate path segments.

.DESCRIPTION
Get-FilePathDelimiter detects whether Path uses backward or forward slashes to separate path segments.  It makes this decision by detecting the first slash in Path.

.OUTPUTS
"/" if the first slash in Path is a forward slash, "\" if it is a backward slash, empty string otherwise.
#>
    [CmdletBinding()]
    param
    (
        # The path whose type to determine.
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
        $mask = '^[^\\\/]*(?<result>[\\\/])'
        ([regex]::Match($Path,$mask)).Groups['result'].Value
    }
}

# The following Cmdlets rely on ParameterSet resolution which doesn't work as expected in PowerShell 2.
if ($PSVersionTable.PSVersion.Major -gt 2)
{
function Assert-ValidFilePathObjectParams
{
    [CmdletBinding()]
    param
    (
        # The file path type of the file path.
        [parameter(position                        = 1,
                   ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('Windows','UNC','unknown')]
        [string]
        $FilePathType,

        # The formatting scheme of the file path.
        [parameter(ParameterSetName                = 'Windows',
                   position                        = 2,
                   ValueFromPipelineByPropertyName = $true)]
         [parameter(ParameterSetName                = 'UNC',
                   position                        = 2,
                   ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('FileUri','PowerShell','LongPowerShell','plain')]
        [string]
        $Scheme='plain',

        # The segments of the local path.  For example, to convert to 'c:\local\path' Segments should be 'local','path'
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [string[]]
        $Segments=@(),

        # The DriveLetter to include in the file path.
        [parameter(ParameterSetName                 = 'Windows',
                   Mandatory                       = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [parameter(ParameterSetName                = 'UNC',
                   ValueFromPipelineByPropertyName = $true)]
        [AllowEmptyString()]
        [string]
        $DriveLetter,

        # The DomainName to include in the file path.
        [parameter(ParameterSetName                = 'UNC',
                   Mandatory                       = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [string]
        $DomainName,

        # Whether or not to include a trailing slash.
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [switch]
        $TrailingSlash,

        # the delimiter to use for unknown FilePathType
        [parameter(ParameterSetName                = 'unknown',
                   Mandatory                       = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [string]
        $Delimiter='\'
    )
    process
    {
        $bp = &(gbpm)

        if
        (
            $bp.Keys -notcontains 'Delimiter' -and
            $FilePathType -eq 'unknown'
        )
        {
            throw New-Object System.ArgumentException(
                'Delimiter must be provided for unknown FilePathType',
                'Delimiter'
            )
        }

        if
        (
            $bp.Keys -contains 'Delimiter' -and
            $FilePathType -ne 'unknown'
        )
        {
            throw New-Object System.ArgumentException(
                "Delimiter cannot be provided for $FilePathType FilePathType",
                'Delimiter'
            )
        }

        if
        (
            $bp.Keys -notcontains 'DomainName' -and
            $FilePathType -eq 'UNC'
        )
        {
            throw New-Object System.ArgumentException(
                'DomainName must be provided for UNC FilePathType',
                'DomainName'
            )
        }

        if
        (
            $FilePathType -eq 'Windows' -and
            $DriveLetter -eq [string]::Empty
        )
        {
            throw New-Object System.ArgumentException(
                'DriveLetter cannot be empty string for Windows FilePathType',
                'DriveLetter'
            )
        }
    }
}
function New-FilePathObject
{
<#
.SYNOPSIS
Create a new file path object.

.DESCRIPTION
New-FilePathObject creates a new file path object according to the parameters provided.  New-FilePathObject deliberately checks for parameters and creates file path object properties to make the object as appropriate as possible for pipeing to ConvertTo-FilePathString.

.OUTPUTS
The file path object if successful.  False otherwise.
.LINK
    ConvertTo-FilePathString
.EXAMPLE
    $fp = New-FilePathObject -FilePathType UNC -DomainName domain.name
    $fp | ConvertTo-FilePathString
    # \\domain.name\
    $fp.Segments += 'a'
    $fp | ConvertTo-FilePathString
    # \\domain.name\a
    $fp.TrailingSlash = $true
    $fp | ConvertTo-FilePathString
    #\\domain.name\a\
    $fp.Scheme = 'FileUri'
    $fp | ConvertTo-FilePathString
    #file://domain.name/a/
#>
    [CmdletBinding()]
    param
    (
        # The file path type of the file path.
        [parameter(Mandatory                       = $true,
                   position                        = 1,
                   ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('Windows','UNC','unknown')]
        [string]
        $FilePathType,

        # The formatting scheme of the file path.
        [parameter(ParameterSetName                = 'Windows',
                   position                        = 2,
                   ValueFromPipelineByPropertyName = $true)]
         [parameter(ParameterSetName                = 'UNC',
                   position                        = 2,
                   ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('FileUri','PowerShell','LongPowerShell','plain')]
        [string]
        $Scheme='plain',

        # The segments of the local path.  For example, to convert to 'c:\local\path' Segments should be 'local','path'
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [string[]]
        $Segments=@(),

        # The DriveLetter to include in the file path.
        [parameter(ParameterSetName                 = 'Windows',
                   Mandatory                       = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [parameter(ParameterSetName                = 'UNC',
                   ValueFromPipelineByPropertyName = $true)]
        [AllowEmptyString()]
        [string]
        $DriveLetter,

        # The DomainName to include in the file path.
        [parameter(ParameterSetName                = 'UNC',
                   Mandatory                       = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [string]
        $DomainName,

        # Whether or not to include a trailing slash.
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [switch]
        $TrailingSlash,

        # the delimiter to use for unknown FilePathType
        [parameter(ParameterSetName                = 'unknown',
                   Mandatory                       = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [string]
        $Delimiter='\'

    )
    process
    {
        $bp = &(gbpm)

        $bp | >> | Assert-ValidFilePathObjectParams

        $bp.TrailingSlash = $TrailingSlash
        $bp.Segments = $Segments
        $bp.Scheme = $Scheme
        $bp.DriveLetter = $DriveLetter

        if
        (
            $FilePathType -eq 'Windows' -and
            $bp.Keys -contains 'DomainName'
        )
        {
            $bp.Remove('DomainName')
        }

        return New-Object PSObject -Property $bp
    }
}
function ConvertTo-FilePathObject
{
<#
.SYNOPSIS
Convert a file path string to an object.

.DESCRIPTION
ConvertTo-FilePathObject converts a Windows or UNC path string to an object representing its constituent parts.  Those constituent parts can then be manipulated on the object and converted to a new path string using ConvertTo-FilePathString.  ConvertTo-FilePathObject accepts formatting "schemes" as follows:

    Scheme         | Examples
    ---------------+---------------------
    plain          | c:\local\path,
                   | \\domain.name\c$\local\path
    FileUri        | file:///c:/local/path
                   | file://domain.name/c$/local/path
    PowerShell     | FileSystem::c:\local\path
                   | FileSystem::\\domain.name\c$\local\path
    LongPowerShell | Microsoft.PowerShell.Core\FileSystem::c:\local\path

The objects produced by ConvertTo-FilePathObject are deliberately designed to match the input parameters of ConvertTo-FilePathString to support pipelining.  See the examples.

.OUTPUTS
An object representing the constituent parts of Path if Path is a recognized format.

.EXAMPLE
    'c:\local\path' | ConvertTo-FilePathObject | % DriveLetter
    # c
.EXAMPLE
    'c:\local\path' | ConvertTo-FilePathObject | % Segments | Select -Last 1
    # path
.EXAMPLE
    $object = 'c:\local\path' | ConvertTo-FilePathObject
    $object.Segments += 'file.txt'
    $object | ConvertTo-FilePathString Windows PowerShell
    # FileSystem::c:\local\path\file.txt

This example demonstrates adding a filename to the path by way of manipulating the Segments property on the resultant object.  The object is then converted to a Windows file path formatted as a PowerShell path.
.EXAMPLE
    'file:///c:/path' | ConvertTo-FilePathObject | ConvertTo-FilePathString -Scheme PowerShell
    # FileSystem::c:\path
This example demonstrates how the output of ConvertTo-FilePathObject matches the parameters of ConvertTo-FilePathString.  This means that you can use the PowerShell's pipeline parameter binding semantics to convert from one scheme to another.
.LINK
    ConvertTo-FilePathObject
    Test-ValidFilePathObject
#>
    [CmdletBinding()]
    param
    (
        # The file path to convert to an object.
        [parameter(mandatory                       = $true,
                   position                        = 1,
                   ValueFromPipeline               = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [AllowEmptyString()]
        [Alias('PSPath')]
        [string]
        $Path
    )
    process
    {
        $type = $Path | Get-FilePathType

        $scheme = $Path | Get-FilePathScheme

        if ( $type -eq 'Windows' )
        {
            return New-Object PSObject -Property @{
                OriginalString = $Path
                DriveLetter = $Path | Get-PartOfWindowsPath DriveLetter
                LocalPath = $Path | Get-PartOfWindowsPath LocalPath
                Segments = $Path | Get-PartOfWindowsPath LocalPath | Split-FilePathFragment
                TrailingSlash = $Path | Get-PartOfWindowsPath LocalPath | Test-FilePathForTrailingSlash
                FilePathType = $type
                Scheme = $scheme
            }
        }
        if ( $type -eq 'UNC' )
        {
            return New-Object PSObject -Property @{
                OriginalString = $Path
                DomainName = $Path | Get-PartOfUncPath DomainName
                DriveLetter = $Path | Get-PartOfUncPath DriveLetter
                LocalPath = $Path | Get-PartOfUncPath LocalPath
                Segments = $Path | Get-PartOfUncPath LocalPath | Split-FilePathFragment
                TrailingSlash = $Path | Get-PartOfUncPath LocalPath | Test-FilePathForTrailingSlash
                FilePathType = $type
                Scheme = $scheme
            }
        }

        $r = @{
            OriginalString = $Path
            Segments = $Path | Split-FilePathFragment
            TrailingSlash = $Path | Test-FilePathForTrailingSlash
            FilePathType = $type
        }

        if ($scheme -ne 'unknown')
        {
            $r.Scheme = $scheme
        }

        $delimiter = $Path | Get-FilePathDelimiter
        if ($delimiter)
        {
            $r.Delimiter = $delimiter
        }
        else
        {
            $r.Delimiter = '\'
        }

        return New-Object PSObject -Property $r
    }
}
function Invoke-CoercionToFilePathObject
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position          = 1,
                   Mandatory         = $true,
                   ValueFromPipeline = $true)]
        $InputObject
    )
    process
    {
        if ($InputObject -is [string] )
        {
            $InputObject | Test-ValidFilePath -ErrorAction Stop | Out-Null
            return $InputObject | ConvertTo-FilePathObject
        }
        if ($InputObject -is [hashtable] )
        {
            $InputObject | >> | Assert-ValidFilePathObjectParams
            return $InputObject | >>
        }
        if ( $InputObject -is [pscustomobject] )
        {
            $InputObject | Assert-ValidFilePathObjectParams
            return $InputObject
        }
        throw New-Object System.ArgumentException(
            'InputObject could not be coerced.',
            'InputObject'
        )

    }
}
function Test-ValidFilePathParams
<#
.SYNOPSIS
Tests file path parameters for validity.

.DESCRIPTION
Test-ValidFilePathParams tests parameters that are critical to input to ConvertTo-FilePathString for validity.  Test-ValidFilePathParams checks the following:

    * Segments using Test-ValidFileName
    * DriverLetter using Test-ValidDriveLetter
    * DomainName using Test-ValidDomainName

.OUTPUTS
True if the parameters are valid.  False otherwise.
#>
{
    [CmdletBinding()]
    param
    (
        [parameter(mandatory                       = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [string[]]
        $Segments,

        [parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({$_ | Test-ValidDriveLetter})]
        [string]
        $DriveLetter,

        [parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({$_ | Test-ValidDomainName})]
        [string]
        $DomainName
    )
    process
    {
        foreach ($segment in $Segments)
        {
            if (-not ($segment | Test-ValidFileName) )
            {
                return $false
            }
        }

        return $true
    }
}
function ConvertTo-FilePathString
{
<#
.SYNOPSIS
Convert to a file path strings of a specified format.

.DESCRIPTION
ConvertTo-FilePathString converts a bunch of parameters to Windows and UNC "file path types" formatted using URI and PowerShell "schemes".  The eight formatting possibilities are as follows:

 FilePathType | Scheme         | Example
 -------------+----------------+-------------------------------------------------------------------
 Windows        plain            c:\local\path
 Windows        FileUri          file:///c:/local/path
 Windows        PowerShell       FileSystem::c:\local\path
 Windows        LongPowerShell   Microsoft.PowerShell.Core\FileSystem::\c:\path
 UNC            plain            \\domain.name\c$\local\path
 UNC            FileUri          file://domain.name/c$/local/path
 UNC            PowerShell       FileSystem::\\domain.name\c$\local\path
 UNC            LongPowerShell   Microsoft.PowerShell.Core\FileSystem::\\domain.name\c$\local\path


Conversion to any combination of FilePathType and Scheme is supported provided all elements required to compose the output string are provided as parameters.

The parameters of ConvertTo-FilePathString are designed to accept the objects produced by ConvertTo-FilePathObject.  This facilitates conversion and injection of parameters on a single line.  See the example.

.OUTPUTS
A string of the file path string if conversion is successful. False otherwise.

.EXAMPLE
    ConvertTo-FilePathString Windows FileUri -DriveLetter c -Segments 'local','path'
    # file:///c:/local/path
.EXAMPLE
    'c:\local\path' | ConvertTo-FilePathObject | ConvertTo-FilePathString UNC FileUri -DomainName domain.name
    # file://domain.name/c$/local/path

This example show how you can convert a plain-old Windows path to the path of an administrative share by injecting the domain name of the host.

.LINK
    ConvertTo-FilePathFormat
    ConvertTo-FilePathObject
    Test-ValidFilePathObject
#>
    [CmdletBinding()]
    param
    (
        # The file path type to convert the other parameters to.
        [parameter(position                        = 1,
                   ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('Windows','UNC','unknown')]
        [string]
        $FilePathType,

        # The formatting scheme to convert the other paramters to.
        [parameter(ParameterSetName                = 'Windows',
                   position                        = 2,
                   ValueFromPipelineByPropertyName = $true)]
         [parameter(ParameterSetName                = 'UNC',
                   position                        = 2,
                   ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('FileUri','PowerShell','LongPowerShell','plain')]
        [string]
        $Scheme='plain',

        # The segments of the local path.  For example, to convert to 'c:\local\path' Segments should be 'local','path'
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [string[]]
        $Segments=@(),

        # The DriveLetter to include in the file path.
        [parameter(ParameterSetName                 = 'Windows',
                   Mandatory                       = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [parameter(ParameterSetName                = 'UNC',
                   ValueFromPipelineByPropertyName = $true)]
        [AllowEmptyString()]
        [string]
        $DriveLetter,

        # The DomainName to include in the file path.
        [parameter(ParameterSetName                = 'UNC',
                   Mandatory                       = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [string]
        $DomainName,

        # Whether or not to include a trailing slash.
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [switch]
        $TrailingSlash,

        # the delimiter to use for unknown FilePathType
        [parameter(ParameterSetName                = 'unknown',
                   Mandatory                       = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [string]
        $Delimiter='\'

    )
    process
    {
        $bp = &(gbpm)

        $bp | >> | Assert-ValidFilePathObjectParams

        if ( $bp.Keys -notcontains 'FilePathType' )
        {
            if ( $bp.Keys -contains 'DomainName' )
            {
                $FilePathType = 'UNC'
            }
            else
            {
                $FilePathType = 'Windows'
            }
        }

        $slash = '\'
        if ( $Scheme -eq 'FileUri' )
        {
            $slash = '/'
        }
        elseif ( $FilePathType -eq 'unknown' )
        {
            $slash = $Delimiter
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
        if ( $Scheme -eq 'LongPowerShell' )
        {
            $prefix = 'Microsoft.PowerShell.Core\FileSystem::'
        }

        if ( $FilePathType -eq 'UNC' )
        {
            return "$prefix$($slash*2)$DomainName$slash$($DriveLetter | ?: "$DriveLetter`$$slash")$($Segments -join $slash)$($TrailingSlash | ?: $slash)"
        }
        if ( $FilePathType -eq 'Windows' )
        {
            return "$prefix$DriveLetter`:$slash$($Segments -join $slash)$($TrailingSlash | ?: $slash)"
        }
        if ( $FilePathType -eq 'unknown' )
        {
            return "$($Segments -join $slash)$($TrailingSlash | ?: $slash)"
        }
    }
}
function Invoke-CoercionToFilePathString
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position          = 1,
                   Mandatory         = $true,
                   ValueFromPipeline = $true)]
        $InputObject
    )
    process
    {
        if ($InputObject -is [string] )
        {
            $InputObject | Test-ValidFilePath -ErrorAction Stop | Out-Null
            return $InputObject
        }
        if ($InputObject -is [hashtable] )
        {
            return $InputObject | >> | ConvertTo-FilePathString
        }
        if ( $InputObject -is [pscustomobject] )
        {
            return $InputObject | ConvertTo-FilePathString
        }
        throw New-Object System.ArgumentException(
            'InputObject could not be coerced.',
            'InputObject'
        )

    }
}
function ConvertTo-FilePathFormat
{
<#
.SYNOPSIS
Convert file path strings from one format to another.

.DESCRIPTION
ConvertTo-FilePathFormat converts between Windows and UNC "file path types" formatted using URI and PowerShell "schemes".  The eight formatting possibilities are as follows:

 FilePathType | Scheme         | Example
 -------------+----------------+-------------------------------------------------------------------
 Windows        plain            c:\local\path
 Windows        FileUri          file:///c:/local/path
 Windows        PowerShell       FileSystem::c:\local\path
 Windows        LongPowerShell   Microsoft.PowerShell.Core\FileSystem::\c:\path
 UNC            plain            \\domain.name\c$\local\path
 UNC            FileUri          file://domain.name/c$/local/path
 UNC            PowerShell       FileSystem::\\domain.name\c$\local\path
 UNC            LongPowerShell   Microsoft.PowerShell.Core\FileSystem::\\domain.name\c$\local\path


Conversion between any combination of FilePathType and Scheme is supported provided all elements required to compose the output string can be extracted from Path.  For example, "\\domain.name\c$\local\path" can be converted to "c:\local\path".  The reverse conversion cannot be made using ConvertTo-FilePathFormat because there is no domain name in "c:\local\path".  See ConvertTo-FilePathString for an example of converting "c:\local\path" to "\\domain.name\c$\local\path" by injecting the domain.name into the conversion.

.OUTPUTS
A string of the file path string if conversion is successful. False otherwise.

.EXAMPLE
    '\\domain.name\c$\local\path' | ConvertTo-FilePathFormat Windows
    # c:\local\path
.EXAMPLE
    '\\domain.name\c$\local\path' | ConvertTo-FilePathFormat Windows PowerShell
    # FileSystem::c:\local\path
.LINK
    ConvertTo-FilePathString
    ConvertTo-FilePathObject
    Test-ValidFilePathObject
#>
    [CmdletBinding()]
    param
    (
        # The file path type to convert Path to.
        [parameter(position                        = 1,
                   ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('Windows','UNC')]
        [string]
        $FilePathType,

        # The formatting scheme to convert Path to.
        [parameter(position                        = 2,
                   ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('FileUri','PowerShell','LongPowerShell','plain')]
        [string]
        $Scheme,

        # The input string to convert.
        [parameter(mandatory                       = $true,
                   position                        = 3,
                   ValueFromPipeline               = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [string]
        $Path
    )
    process
    {
        $inputObject = $Path | ConvertTo-FilePathObject

        if
        (
            $FilePathType -eq 'UNC' -and
            -not $inputObject.DomainName
        )
        {
            throw New-Object System.ArgumentException(
                "UNC paths require a domain name but Path $Path does not seem to contain one.",
                'Path'
            )
        }

        if
        (
            $FilePathType -eq 'Windows' -and
            -not $inputObject.DriveLetter
        )
        {
            throw New-Object System.ArgumentException(
                "Windows paths require a drive letter but Path $Path does not seem to contain one.",
                'Path'
            )
        }

        $splat = &(gbpm)
        $splat.Remove('Path')

        return $inputObject | ConvertTo-FilePathString @splat
    }
}
function Join-FilePath
{
<#
.SYNOPSIS
Joins file path elements.

.DESCRIPTION
Join-FilePath joins the file path Elements piped to it.  Elements are examined and manipulated as follows:

    * The first Element is decomposed to object form by ConvertTo-FilePathObject and form the basis of the output Path.  This means that path-wide properties like whether the path will be output as a plain or PowerShell path are determined from the first element.
    * All Elements are split using Split-FilePathFragment to determine the path segments.
    * The last element is inspected for a trailing slash using Test-FilePathForTrailingSlash to determine whether the output will have a trailing slash.

Join-FilePath does not resolve paths so that resolution of joined paths can be delayed until after subsequent manipulation.

Join-FilePath does test file path segments, domain names, or drive letters for validity because those characters may be substituted by further string manipulation prior to use.  Use Test-ValidFilePath to test for validity.

.OUTPUTS
The path representing the joining of all Elements in the pipeline.

.EXAMPLE
    'a','b' | Join-FilePath
    # a\b
.EXAMPLE
    'c:\path','segments' | Join-FilePath
    # c:\path\segments
.EXAMPLE
    'file:///c:','path\segments' | Join-FilePath
    # file:///c:/path/segments
.EXAMPLE
    '\\domain.name','path\','segment/' | Join-FilePath
    # \\domain.name\path\segment\
.LINK
    ConvertTo-FilePathObject
    Test-ValidFilePath
#>
    [CmdletBinding()]
    param
    (
        [parameter(mandatory                       = $true,
                   ValueFromPipeline               = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [AllowEmptyString()]
        [string]
        $Element
    )
    begin
    {
        $firstElement = $true
    }
    process
    {
        if ( $firstElement )
        {
            $object = $Element | ConvertTo-FilePathObject
            if ( $object.FilePathType -eq 'unknown' )
            {
                $object.Segments = @($Element | ? { $_ -ne [string]::Empty })
            }

            $firstElement = $false
        }
        else
        {
            $object.Segments = @($object.Segments) +($Element | Split-FilePathFragment)
        }
    }
    end
    {
        $ts = @{
            TrailingSlash = $Element | Test-FilePathForTrailingSlash
        }
        $object | ConvertTo-FilePathString @ts
    }
}
Function Resolve-FilePathSegments
{
<#
.SYNOPSIS
Resolve file path segments in the pipeline.

.DESCRIPTION
Resolve-FilePathSegments resolves file path segments in the pipeline according to customary interpretation of "." and ".." segments.

.OUTPUTS
A list of path segments representing the resolved path if successful.  False otherwise.
.EXAMPLE
    'a','..','b' | Resolve-FilePathSegments
    # b
.EXAMPLE
    'a','b','.','c' | Resolve-FilePathSegments
    # a
    # b
    # c
#>
    [CmdletBinding()]
    param
    (
        # A segment to resolve.
        [parameter(mandatory                       = $true,
                   ValueFromPipeline               = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [string]
        $Segment
    )
    begin
    {
        $segments = @()
    }
    process
    {
        if ($Segment -eq '..')
        {
            if ($segments.Count -eq 0)
            {
                throw New-Object System.ArgumentException(
                    'Path could not be resolved because too many ".." segments were provided.',
                    'Segment'
                )
            }
            if ( $segments.Count -eq 1 )
            {
                $segments = @()
            }
            else
            {
                $segments = $segments[0..($segments.Count-2)]
            }
        }

        if ('..','.' -notcontains $Segment)
        {
            $segments += $Segment
        }
    }
    end
    {
        return $segments
    }
}
function Resolve-FilePath
{
<#
.SYNOPSIS
Resolve a file path.

.DESCRIPTION
Resolve-FilePath resolves a file path according to customary interpretation of "." and ".." segments.

.OUTPUTS
The resolved path if successful. False otherwise.
.EXAMPLE
    'a/../b/c' | Resolve-FilePath
    # b/c
.EXAMPLE
    'file://domain.name/c$/a/../b/c' | Resolve-FilePath
    # file://domain.name/c$/b/c
.EXAMPLE
    'FileSystem::c:\a\b\c' | Resolve-FilePath
    # FileSystem::c:\a\b\c
#>
    [CmdletBinding()]
    param
    (
        # The path to resolve.
        [parameter(mandatory                       = $true,
                   position                        = 1,
                   ValueFromPipeline               = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [string]
        $Path
    )
    process
    {
        $object = $Path | ConvertTo-FilePathObject

        if
        ( -not
            (
                $object.Segments = $object.Segments |
                    Resolve-FilePathSegments
            )
        )
        {
            return $false
        }

        return $object | ConvertTo-FilePathString
    }
}
function Test-FilePath
{
    [CmdletBinding()]
    param
    (
        # The path to resolve.
        [parameter(mandatory                       = $true,
                   position                        = 1,
                   ValueFromPipeline               = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [Alias('PathString','PathHashtable')]
        $PathObject,

        [parameter(position                        = 3,
                   ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('Directory','File','Any')]
        [string]
        $ItemType
    )
    process
    {
        if ( $PathObject -is [hashtable] )
        {
            $PathObject | >> | Test-ValidFilePathParams -ErrorAction Stop | Out-Null
            $PathString = $PathObject | >> | ConvertTo-FilePathString
        }
        elseif ( $PathObject -is [string] )
        {
            $PathObject | Test-ValidFilePath -ErrorAction Stop | Out-Null
            $PathString = $PathObject
        }
        elseif ( $PathObject -is [pscustomobject] )
        {
            $PathObject | Test-ValidFilePathParams -ErrorAction Stop | Out-Null
            $PathString = $PathObject | ConvertTo-FilePathString
        }
        else
        {
            $PathObject | Test-ValidFilePath -ErrorAction Stop | Out-Null
            $PathString = $PathObject
        }

        $splat = @{}
        if ($ItemType)
        {
            $splat = @{
                PathType = @{
                    Any = 'Any'
                    Directory = 'Container'
                    File = 'Leaf'
                }.$ItemType
            }
        }

        if ( -not ($PathString | Test-Path @splat) )
        {
            &(Publish-Failure "$ItemType $PathString does not exist." ([System.IO.FileNotFoundException]))
            return $false
        }
        return $true
    }
}
function Test-FilePathsAreEqual
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position                        = 1,
                   Mandatory                       = $true,
                   ValueFromPipelineByPropertyName = $true)]
        $PathA,

        [Parameter(Position                        = 2,
                   Mandatory                       = $true,
                   ValueFromPipelineByPropertyName = $true)]
        $PathB
    )
    process
    {
        $pathStringA = $PathA | CoerceTo-FilePathString | Resolve-FilePath
        $pathStringB = $PathB | CoerceTo-FilePathString | Resolve-FilePath

        return $pathStringA -eq $pathStringB
    }
}
function ConvertTo-RelativeFilePathSegments
{
    [CmdletBinding()]
    param
    (
        # The Path whose relative segments to extract.
        [parameter(mandatory                       = $true,
                   position                        = 1,
                   ValueFromPipeline               = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({$_ | >> | Test-ValidFilePathParams})]
        [hashtable]
        $Path,

        # The (shorter) base that Path is relative to.
        [parameter(mandatory                       = $true,
                   position                        = 2,
                   ValueFromPipeline               = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({$_ | >> | Test-ValidFilePathParams})]
        [hashtable]
        $Base
    )
    process
    {
        if ( $Path.DomainName -ne $Base.DomainName )
        {
            throw New-Object System.ArgumentException(
                'Path and Base DomainNames do not match.',
                'Base'
            )
        }
        if ( $Path.DriveLetter -ne $Base.DriveLetter )
        {
            throw New-Object System.ArgumentException(
                'Path and Base DriveLetters do not match.'
            )
        }
        $i = 0
        foreach ( $segment in $Base.Segments )
        {
            if ( $segment -ne $Path.Segments[$i] )
            {
                throw New-Object System.ArgumentException(
                    "Base segment $segment does not match Path segment $($Path.Segments[$i])."
                )
            }
            $i++
        }

        $i = 1
        foreach ( $segment in $Path.Segments )
        {
            if ( $i -gt $Base.Segments.Count )
            {
                $segment
            }
            $i++
        }
    }
}
}
