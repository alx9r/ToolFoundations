function Get-StringHash
{
    [CmdletBinding()]
    [OutputType([string])]
    param
    (
        [Parameter(Position = 1,
                   ValueFromPipeline = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [AllowNull()]
        [string]
        $InputString,

        [Parameter(Position = 2,
                   ValueFromPipelineByPropertyName = $true)]
        [System.Text.Encoding]
        $InputEncoding = [System.Text.Encoding]::UTF8,

        [Parameter(Position = 3,
                   ValueFromPipelineByPropertyName = $true)]
        [System.Security.Cryptography.HashAlgorithm]
        $Algorithm = (New-Object System.Security.Cryptography.SHA256CryptoServiceProvider),

        [Parameter(Position = 4,
                   ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('hexadecimal','base64')]
        [string]
        $OutputEncoding = 'hexadecimal'
    )
    process
    {
        if
        (
            $null -eq $InputString -or
            $InputString -eq [string]::Empty
        )
        {
            return [string]::Empty
        }

        $bytes = $InputEncoding.GetBytes($InputString)
        $hashByteArray = $algorithm.ComputeHash($bytes)

        Switch ($OutputEncoding)
        {
            'hexadecimal' {[System.BitConverter]::ToString($hashByteArray).Replace('-','')}
            'base64' {[System.Convert]::ToBase64String($hashByteArray)}
        }
    }
}
