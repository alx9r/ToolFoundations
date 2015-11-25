Set-Alias Process-IdemFile Invoke-ProcessIdemFile

if ($PSVersionTable.PSVersion.Major -ge 4)
{
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
        [ValidateScript({$_ | >> | Test-ValidFilePathParams})]
        [hashtable]
        $Path,

        [parameter(Mandatory                       = $true,
                   position                        = 3,
                   ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('Directory','File')]
        [string]
        $ItemType,

        [parameter(position                        = 4,
                   ValueFromPipelineByPropertyName = $true)]
        $FileContents,

        [parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({$_ | >> | Test-ValidFilePathParams})]
        [hashtable]
        $CopyPath
    )
    process
    {
        if ( (&(gbpm)).Keys -contains 'CopyPath' )
        {
            $pathStr = $Path | >> | ConvertTo-FilePathString | Resolve-FilePath
            $copyPathStr = $CopyPath | >> | ConvertTo-FilePathString | Resolve-FilePath

            if ( $pathStr -eq $copyPathStr )
            {
                throw New-Object System.ArgumentException(
                    "Path and CopyPath are the same: $pathStr",
                    'CopyPath'
                )
            }
        }

        # recursive check of folder contents is not yet implemented
        if ( $ItemType -eq 'Directory' -and $CopyPath )
        {
            throw New-Object System.NotImplementedException(
                'Copying of directories is not yet implemented.'
            )
        }

        # validate presence of FileContents
        if ($FileContents -and $ItemType -ne 'File')
        {
            throw New-Object System.ArgumentException(
                'FileContents provided for a directory.',
                'FileContents'
            )
        }

        # FileContents and CopyPath are mutually exclusive
        if ($FileContents -and $CopyPath)
        {
            throw New-Object System.ArgumentException(
                'Both CopyPath and FileContents were provided.',
                'CopyPath'
            )
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
        [ValidateScript({$_ | >> | Test-ValidFilePathParams})]
        [hashtable]
        $Path,

        [parameter(Mandatory                       = $true,
                   position                        = 3,
                   ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('Directory','File')]
        [string]
        $ItemType,

        [parameter(position                        = 4,
                   ValueFromPipelineByPropertyName = $true)]
        $FileContents,

        [parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({$_ | >> | Test-ValidFilePathParams})]
        [hashtable]
        $CopyPath
    )
    process
    {
        &(gbpm) | >> | Assert-ValidIdemFileParams

        # Test CopyPath exists
        if
        (
            $CopyPath -and
            -not ($CopyPath | Test-FilePath -ItemType $ItemType)
        )
        {
            $copyPathStr = $CopyPath | >> | ConvertTo-FilePathString
            &(Publish-Failure "CopyPath $copyPathStr does not exist.", 'CopyPath' ([System.ArgumentException]))
            return $false
        }

        # Calculate the source file hash. This might be expensive and
        # will be needed multiple times.
        if ( $CopyPath -and $ItemType -eq 'File' )
        {
            $copyPathStr = $CopyPath | >> | ConvertTo-FilePathString
            $sourceFileHash = (Get-FileHash $copyPathStr).Hash
        }

        ## test if the item exists at Path, create it or copy it if necessary

        if ( $CopyPath )
        {
            $Test = {
                if (-not ($Path | Test-FilePath -ItemType $ItemType))
                {
                    return $false
                }
                $pathStr = $Path | >> | ConvertTo-FilePathString
                return (Get-FileHash $pathStr).Hash -eq $sourceFileHash
            }
            $Remedy = {
                $splat = @{
                    Path = $CopyPath | >> | ConvertTo-FilePathString
                    Destination = $Path | >> | ConvertTo-FilePathString
                    Recurse = ($ItemType -eq 'Directory')
                }
                Copy-Item @splat
            }
        }
        else
        {
            $Test = {$Path | Test-FilePath -ItemType $ItemType}
            $Remedy = {
                $splat = @{
                    Path = $Path | >> | ConvertTo-FilePathString
                    ItemType = $ItemType
                }
                New-Item @splat
            }
        }

        $pathResult = Process-Idempotent $Mode $Test $Remedy

        if ( -not $pathResult )
        {
            $pathStr = $Path | >> | ConvertTo-FilePathString
            &(Publish-Failure "$Mode failed for $pathStr." ([System.IO.FileNotFoundException]))
            return $false
        }


        ## test the file contents, correct them if necessary

        if ( (&(gbpm)).Keys -contains 'FileContents' )
        {
            $Test = {
                $splat = @{
                    Path = $Path | >> | ConvertTo-FilePathString
                    Raw = $true
                }
                (Get-Content @splat) -eq $FileContents
            }
            $Remedy = {
                $splat = @{
                    FilePath = $Path | >> | ConvertTo-FilePathString
                    Encoding = 'ascii'
                }
                Out-File @splat | Out-Null
            }
            $fileContentsResult = Process-Idempotent $Mode $Test $Remedy

            if ( -not $fileContentsResult )
            {
                $pathStr = $Path | >> | ConvertTo-FilePathString
                &(Publish-Failure "$Mode FileContents failed for $pathStr." ([System.IO.FileNotFoundException]))
                return $false
            }
        }

        ## return the result

        return $pathResult,$fileContentsResult |
            Sort-Object |
            Select -Last 1
    }
}


Function Test-oltkDSFsItem
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory                       = $true,
                   position                        = 1,
                   ValueFromPipeline               = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [string]
        $Path,

        [parameter(Mandatory                       = $true,
                   position                        = 2,
                   ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('Directory','File')]
        [string]
        $ItemType,

        [parameter(position                        = 3,
                   ValueFromPipelineByPropertyName = $true)]
        $FileContents,

        [parameter(ValueFromPipelineByPropertyName = $true)]
        [string]
        $CopyPath
    )
    process
    {
        # recursive check of folder contents is not yet implemented
        if ( $ItemType -eq 'Directory' -and $CopyPath )
        {
            Write-Error "Not yet implemented: Test-oltkDSFsItem didn't check that the contents of folder `"$Path`" and `"$CopyPath`" match."
            return $false
        }

        # validate presence of FileContents
        if ($FileContents -and $ItemType -ne 'File')
        {
            Write-Error 'FileContents provided for a directory.'
            return $false
        }

        # FileContents and CopyPath are mutually exclusive
        if ($FileContents -and $CopyPath)
        {
            Write-Error 'Both CopyPath and FileContents were provided.'
            return $false
        }

        # Test CopyPath exists
        if ( $CopyPath -and -not (Test-oltkPath $CopyPath $ItemType) )
        {
            Write-Error "The CopyPath `"$CopyPath`" does not exist."
            return $false
        }

        # test for the existence of the item
        if ( -not (Test-oltkPath $Path $ItemType) )
        {
            Write-Verbose "$ItemType `"$Path`" does not exist."
            return $false
        }

        # if we're not checking file contents, we're done
        if ( -not $FileContents -and -not $CopyPath )
        {
            return $true
        }

        # get the file contents if necessary
        if ( $CopyPath )
        {
            $copyPathHash = Get-oltkFileHash $CopyPath
        }

        # test that the file's contents are correct
        if
        (
            (
                $CopyPath -and
                ((Get-oltkFileHash $Path) -ne $copyPathHash)
            ) -or
            (
                -not $CopyPath -and
                ((Get-Content $Path -Raw) -ne $FileContents)
            )
        )
        {
            Write-Verbose "The contents of `"$Path`" are incorrect."
            return $false
        }

        return $true
    }
}
}
