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
                (Get-Content @splat | Remove-TrailingNewlines) -eq ($FileContents | Remove-TrailingNewlines)
            }
            $Remedy = {
                $splat = @{
                    FilePath = $Path | >> | ConvertTo-FilePathString
                    Encoding = 'ascii'
                }
                $FileContents | Out-File @splat | Out-Null
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
Function Remove-TrailingNewlines
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory                       = $true,
                   position                        = 1,
                   ValueFromPipeline               = $true,
                   ValueFromPipelineByPropertyName = $true  )]
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
}
