$tempPsm1Guid = 'b3cd95fc-1569-4170-a1f4-4eb50efbe289'

function Get-TempPsm1Path
{
    param
    (
        [Parameter(Mandatory = $true,
                   ValueFromPipeline = $true)]
        $Name
    )
    process
    {
        "$([System.IO.Path]::GetTempPath())$Name.psm1"
    }
}

function New-Psm1Module
{
    # keeping parity with the signature of `New-Module` would
    # go a long way to performing pairs of tests using dynamic
    # and file-backed modules
    param
    (
        [Parameter(Mandatory = $true,
                   ValueFromPipeline = $true,
                   Position = 1)]
        [string]
        $Name,

        [Parameter(Mandatory = $true,
                   Position = 2)]
        [scriptblock]
        $Scriptblock,

        [Object[]]
        $ArgumentList = @()
    )
    process
    {
        $Name |
            New-Psm1File -Scriptblock $Scriptblock |
            Import-Module -ArgumentList $ArgumentList -PassThru
    }
}

function New-Psm1File
{
    param
    (
        [Parameter(Mandatory = $true,
                   ValueFromPipeline = $true,
                   Position = 1)]
        [string]
        $Name,

        [Parameter(Mandatory = $true,
                   Position = 2)]
        [scriptblock]
        $Scriptblock
    )
    process
    {
        $path = $Name | Get-TempPsm1Path
        [string]$Scriptblock | Set-Content $path
        $path
    }
}
