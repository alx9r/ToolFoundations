<#
This tests that certain variable names commonly used in x.Tests.ps1
files are not already defined in the environment in which this test
script is running.
#>

Describe 'Global variable naming conflict avoidance' {
    Context 'variable names commonly used in Pester test files' {
        foreach ( $variableName in @(
                'module'
                'h'
                'f'
                'g'
                'v'
                '_testFile'
                'guid'
            )
        )
        {
            It "variable name $variableName is not a global variable" {
                $r = Get-Variable $variableName -Scope Global -ea SilentlyContinue
                $r | Should beNullOrEmpty
            }
            It "variable name $variableName is not in this scope" {
                $r = Get-Variable $variableName -ea SilentlyContinue
                $r | Should beNullOrEmpty
            }
        }
    }
}
