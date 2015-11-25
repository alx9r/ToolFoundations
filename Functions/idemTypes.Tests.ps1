Import-Module ToolFoundations -Force

Describe IdempotentResult {
    It 'all values evaluate to true.' {
        [IdempotentResult]'NoChangeRequired' | Should be $true
        [IdempotentResult]'RequiredChangesApplied' | Should be $true
    }
}
