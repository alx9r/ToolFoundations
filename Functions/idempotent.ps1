Set-Alias Process-Idempotent Invoke-ProcessIdempotent

function Assert-ValidProcessIdempotentParams
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true,
                   Position = 1,
                   ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('Set','Test')]
        [IdempotentProcessMode]
        $Mode,

        [Parameter(Mandatory = $true,
                   Position = 2,
                   ValueFromPipelineByPropertyName = $true)]
        [scriptblock]
        $Test,

        [Parameter(Position = 3,
                   ValueFromPipelineByPropertyName = $true)]
        [scriptblock]
        $Remedy
    )
    process
    {
        if
        (
            $Mode -eq 'Set' -and
            -not $Remedy
        )
        {
            throw New-Object System.ArgumentException(
                'Remedy must be provided when Mode is "Set"',
                'Remedy'
            )
        }

    }
}
function Invoke-ProcessIdempotent
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true,
                   Position = 1,
                   ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('Set','Test')]
        [IdempotentProcessMode]
        $Mode,

        [Parameter(Mandatory = $true,
                   Position = 2,
                   ValueFromPipelineByPropertyName = $true)]
        [scriptblock]
        $Test,

        [Parameter(Position = 3,
                   ValueFromPipelineByPropertyName = $true)]
        [scriptblock]
        $Remedy
    )
    process
    {
        &(gbpm) | >> | Assert-ValidProcessIdempotentParams

        if ( & $Test )
        {
            return [IdempotentResult]::NoChangeRequired
        }
        if ( $Mode -eq 'Test' )
        {
            return $false
        }

        & $Remedy | Out-Null

        if ( & $Test )
        {
            return [IdempotentResult]::RequiredChangesApplied
        }
        return $false
    }
}
