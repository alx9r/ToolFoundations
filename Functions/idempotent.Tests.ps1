Import-Module ToolFoundations -Force

Describe Assert-ValidProcessIdempotentParams {
    It 'throws correct exception when Remedy is absent for Set.' {
        try
        {
            Process-Idempotent Set {}
        }
        catch [System.ArgumentException]
        {
            $threw = $true
            $_.Exception.Message | Should match 'Remedy must be provided when Mode is "Set"'
        }
        $threw | should be $true
    }
}
Describe 'Process-Idempotent Test' {
    It 'returns false when test fails.' {
        $r = Process-Idempotent Test {$false}
        $r | Should be $false
    }
    It 'returns NoChangeRequired when test succeeds.' {
        $r = Process-Idempotent Test {$true}
        $r -eq [IdempotentResult]::NoChangeRequired | Should be $true
    }
}
Describe 'Process-Idempotent Set' {
    It 'returns NoChangeRequired when test succeeds immediately.' {
        $r = Process-Idempotent Set {$true} {'junk'}
        $r -eq [IdempotentResult]::NoChangeRequired | Should be $true
    }
    It 'returns RequiredChangesApplied when test succeeds after remedy.' {
        $state = @{correct=$false}
        $splat = @{
            Test   = {$state.correct}
            Remedy = {$state.correct=$true}
        }
        $r = Process-Idempotent Set @splat
        $r -eq [IdempotentResult]::RequiredChangesApplied | Should be $true
    }
    It 'returns false when test fails after remedy.' {
        $r = Process-Idempotent Set {$false} {'junk'}
        $r | Should be $false
    }
}
