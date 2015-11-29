Set-Alias Process-IdemSignedScript Invoke-ProcessIdemSignedScript

Function Invoke-ProcessIdemSignedScript
{
    [CmdletBinding()]
    param
    (
        [parameter(position = 1,
                   mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('set','test')]
        $Mode,

        [Parameter(position = 2,
                   Mandatory = $true,
                   ValueFromPipeline = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({$_ | >> | Test-ValidFilePathParams})]
        [hashtable]
        $Path,

        [parameter(position = 3,
                   Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [string]
        $FileContent,

        [parameter(ValueFromPipelineByPropertyName = $true)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]
        $Certificate = (Get-ChildItem cert:currentuser\my\ -CodeSigningCert)
    )
    process
    {
        $steps = @(
            @{
                Test = {
                    $splat = @{
                        ScriptPath = $Path
                        RefContent = $FileContent
                    }
                    return Compare-SignedScriptContent @splat
                }
                Remedy = {
                    $splat = @{
                        Path = $Path
                        FileContent = $FileContent
                        ItemType = 'File'
                    }
                    Process-IdemFile set @splat | Out-Null
                }
            }
            @{
                Test = { $Path | Test-ValidScriptSignature }
                Remedy = {
                    $splat = @{
                        FilePath = $Path | >> | ConvertTo-FilePathString
                        Certificate = $Certificate
                        TimeStampServer = 'http://timestamp.comodoca.com/authenticode'
                    }
                    Set-AuthenticodeSignature @splat | Out-Null
                }
            }
        )

        $results = @()
        foreach ( $step in $steps )
        {
            $results += Process-Idempotent $Mode @step
            if ( -not $results[-1] )
            {
                return $false
            }
        }

        return $results |
            Sort-Object |
            select -Last 1
    }
}
function Compare-SignedScriptContent
{
    [CmdletBinding()]
    param
    (
        [Parameter(position = 1,
                   Mandatory = $true,
                   ValueFromPipeline = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({$_ | >> | Test-ValidFilePathParams})]
        [hashtable]
        $ScriptPath,

        [parameter(position = 3,
                   Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [AllowEmptyString()]
        [string]
        $RefContent
    )
    process
    {
        $splat = @{
            Path = $ScriptPath | >> | ConvertTo-FilePathString
        }
        $rawFileContent = Get-RawContent @splat

        if
        (
            $null -eq $rawFileContent -and
            $RefContent -eq [string]::Empty
        )
        {
            return $true
        }
        if ( $null -eq $rawFileContent )
        {
            return $false
        }

        $fileContent = [regex]::Split(($rawFileContent),'# SIG # Begin signature block' )[0]

        ($fileContent | Remove-TrailingNewlines)-eq ($RefContent | Remove-TrailingNewlines)
    }
}
function Test-ValidScriptSignature
{
    [CmdletBinding()]
    param
    (
        [Parameter(position = 1,
                   Mandatory = $true,
                   ValueFromPipeline = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({$_ | >> | Test-ValidFilePathParams})]
        [hashtable]
        $ScriptPath
    )
    process
    {
        $pathStr = $Path | >> | ConvertTo-FilePathString
        (Get-AuthenticodeSignature $pathStr).Status -eq 'Valid'
    }
}
