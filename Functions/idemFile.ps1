Set-Alias Process-IdemFile Invoke-ProcessIdemFile

if ($PSVersionTable.PSVersion.Major -ge 4)
{
Import-Module Microsoft.PowerShell.Utility
Function Assert-ValidIdemFileParams
{
    [CmdletBinding()]
    param
    (
        [parameter(position = 1,
                   mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('set','test')]
        $Mode,

        [parameter(Mandatory                       = $true,
                   position                        = 2,
                   ValueFromPipelineByPropertyName = $true)]
        $Path,

        [parameter(Mandatory                       = $true,
                   position                        = 3,
                   ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('Directory','File')]
        [string]
        $ItemType,

        [parameter(position                        = 4,
                   ValueFromPipelineByPropertyName = $true)]
        $FileContent,

        [parameter(ValueFromPipelineByPropertyName = $true)]
        $CopyPath,

        [parameter(ValueFromPipelineByPropertyName = $true)]
        [switch]
        $CreateParentFolders
    )
    process
    {
        if ( (&(gbpm)).Keys -contains 'CopyPath' )
        {
            if ( Test-FilePathsAreEqual $Path $CopyPath )
            {
                throw New-Object System.ArgumentException(
                    "Path and CopyPath are the same: $($Path | CoerceTo-FilePathString)",
                    'CopyPath'
                )
            }
        }

        # recursive check of folder contents is not yet implemented
        if ( $ItemType -eq 'Directory' -and $CopyPath )
        {
            throw New-Object System.NotImplementedException(
                'Copying of directories is not supported.'
            )
        }

        # validate presence of FileContent
        if ($FileContent -and $ItemType -ne 'File')
        {
            throw New-Object System.ArgumentException(
                'FileContent provided for a directory.',
                'FileContent'
            )
        }

        # FileContent and CopyPath are mutually exclusive
        if ($FileContent -and $CopyPath)
        {
            throw New-Object System.ArgumentException(
                'Both CopyPath and FileContent were provided.',
                'CopyPath'
            )
        }

        # confirm that Path can be coerced to file path object
        $Path | CoerceTo-FilePathObject | Out-Null

        # confirm that CopyPath can be coerced to file path object
        if ( $CopyPath )
        {
            $CopyPath | CoerceTo-FilePathObject | Out-Null
        }
    }
}

Function Invoke-ProcessIdemFile
{
    [CmdletBinding()]
    param
    (
        [parameter(position = 1,
                   mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('set','test')]
        $Mode,

        [parameter(Mandatory                       = $true,
                   position                        = 2,
                   ValueFromPipelineByPropertyName = $true)]
        $Path,

        [parameter(Mandatory                       = $true,
                   position                        = 3,
                   ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('Directory','File')]
        [string]
        $ItemType,

        [parameter(position                        = 4,
                   ValueFromPipelineByPropertyName = $true)]
        $FileContent,

        [parameter(ValueFromPipelineByPropertyName = $true)]
        $CopyPath,

        [parameter(ValueFromPipelineByPropertyName = $true)]
        [switch]
        $CreateParentFolders
    )
    process
    {
        &(gbpm) | >> | Assert-ValidIdemFileParams

        # work with well-formed file path objects
        $pathObj = $Path | CoerceTo-FilePathObject
        if ( $CopyPath )
        {
            $copyPathObj = $CopyPath | CoerceTo-FilePathObject
        }

        # Test CopyPath exists
        if
        (
            $copyPathObj -and
            -not ($copyPathObj | Test-FilePath -ItemType $ItemType -ea si)
        )
        {
            $copyPathStr = $CopyPath | >> | CoerceTo-FilePathString
            &(Publish-Failure "CopyPath $copyPathStr does not exist.", 'CopyPath' ([System.ArgumentException]))
            return $false
        }

        # Calculate the source file hash. This might be expensive and
        # will be needed multiple times.
        if ( $copyPathObj -and $ItemType -eq 'File' )
        {
            $copyPathStr = $CopyPath | >> | ConvertTo-FilePathString
            $sourceFileHash = Get-FileHash $copyPathStr
        }

        ## test if the item exists at Path, create it or copy it if necessary
        ## project missing parent folders if necessary

        if ( $copyPathObj )
        {
            $Test = {$sourceFileHash | Test-FileHash -Path ($pathObj | CoerceTo-FilePathString)}
            $Remedy = {
                if
                (
                    $CreateParentFolders -and
                    $pathObj.Segments.Count -gt 1
                )
                {
                    $projectPath = $pathObj.PsObject.Copy()
                    $projectPath.Segments = $pathObj.Segments[0..($pathObj.Segments.Count-2)]
                    if ( -not (  $projectPath | Test-FilePath -ea si) )
                    {
                        $splat = @{
                            Path = $projectPath | >> | ConvertTo-FilePathString
                            ItemType = 'Directory'
                            Force = $true
                        }
                        New-Item @splat -ea Stop
                    }
                }
                $splat = @{
                    Path = $copyPathObj | CoerceTo-FilePathString
                    Destination = $pathObj | CoerceTo-FilePathString
                }
                Copy-Item @splat -ea Stop
            }
        }
        else
        {
            $Test = {$pathObj | Test-FilePath -ItemType $ItemType -ea si}
            $Remedy = {
                $splat = @{
                    Path = $pathObj | CoerceTo-FilePathString
                    ItemType = $ItemType
                    Force = $CreateParentFolders
                }
                New-Item @splat -ea Stop
            }
        }

        $pathResult = Process-Idempotent $Mode $Test $Remedy

        if ( -not $pathResult )
        {
            $pathStr = $pathObj | CoerceTo-FilePathString
            &(Publish-Failure "$Mode failed for $pathStr." ([System.IO.FileNotFoundException]))
            return $false
        }


        ## test the file contents, correct them if necessary

        if ( (&(gbpm)).Keys -contains 'FileContent' )
        {
            $Test = { $pathObj | ConvertTo-Hashtable | Compare-FileContent -Content $FileContent }
            $Remedy = {
                $splat = @{
                    FilePath = $pathObj | CoerceTo-FilePathString
                    Encoding = 'ascii'
                }
                $FileContent | Out-File @splat -ea Stop | Out-Null
            }
            $fileContentResult = Process-Idempotent $Mode $Test $Remedy

            if ( -not $fileContentResult )
            {
                $pathStr = $pathObj | CoerceTo-FilePathString
                &(Publish-Failure "$Mode FileContent failed for $pathStr." ([System.IO.FileNotFoundException]))
                return $false
            }
        }

        ## return the result

        return $pathResult,$fileContentResult |
            Sort-Object |
            Select -Last 1
    }
}
function Test-FileHash
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory                       = $true,
                   position                        = 1,
                   ValueFromPipelineByPropertyName = $true  )]
        [string]
        $Hash,

        [parameter(Mandatory                       = $true,
                   position                        = 2,
                   ValueFromPipelineByPropertyName = $true  )]
        [ValidateSet('SHA1','SHA256','SHA384','SHA512',
                     'MACTripleDES','MD5','RIPEMD160')]
        [string]
        $Algorithm,

        [parameter(Mandatory                       = $true,
                   position                        = 2,
                   ValueFromPipelineByPropertyName = $true  )]
        [ValidateScript({$_ | Test-ValidFilePath})]
        [string]
        $Path
    )
    process
    {
        if ( -not ($Path | Test-Path -PathType Leaf ) )
        {
            return $false
        }

        $splat = @{
            Algorithm = $Algorithm
            LiteralPath = $Path
        }
        return (Get-FileHash @splat).Hash -eq $Hash
    }
}
function Compare-FileContent
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory                       = $true,
                   position                        = 1,
                   ValueFromPipelineByPropertyName = $true  )]
        [AllowEmptyString()]
        [string]
        $Content,

        [parameter(Mandatory                       = $true,
                   position                        = 2,
                   ValueFromPipeline               = $true,
                   ValueFromPipelineByPropertyName = $true  )]
        [ValidateScript({$_ | >> | Test-ValidFilePathParams})]
        [hashtable]
        $Path
    )
    process
    {
        if ( -not ($Path | Test-FilePath) )
        {
            return $false
        }

        $splat = @{
            Path = $Path | >> | ConvertTo-FilePathString
        }
        "$(Get-RawContent @splat | Remove-TrailingNewlines)" -eq "$($Content | Remove-TrailingNewlines)"
    }
}
}
Function Remove-TrailingNewlines
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory                       = $true,
                   position                        = 1,
                   ValueFromPipeline               = $true,
                   ValueFromPipelineByPropertyName = $true  )]
        [AllowEmptyString()]
        [string]
        $InputObject
    )
    process
    {
        $acc = $InputObject
        while
        (
            $acc[-1] -eq "`n" -or
            $acc[-1] -eq "`r"
        )
        {
            $acc = $acc.Substring(0,$acc.Length-1)
        }
        return $acc
    }
}
function Get-RawContent
{
# this exists because the Get-Content -Raw option does not seem to work reliably on all systems.
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory                       = $true,
                   position                        = 1,
                   ValueFromPipeline               = $true,
                   ValueFromPipelineByPropertyName = $true  )]
        [ValidateScript({$_ | Test-ValidFilePath})]
        [string]
        $Path
    )
    process
    {
        if ( -not (Test-Path $Path) )
        {
            return
        }
        [System.IO.File]::ReadAllText($Path)
    }
}
