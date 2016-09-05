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
$guid = [guid]::NewGuid().GUID.Split('-')[0]
Describe 'Global variable accessibility' {
    $module = New-Module (
        [scriptblock]::Create(
            @"
            function f-$guid {
                `$v_$guid
            }
"@
        )
    )
    It 'create a global variable' {
        Set-Variable "v_$guid" 'global variable' -Scope Global
    }
    It 'read that variable back' {
        Get-Variable "v_$guid" -ValueOnly | Should be 'global variable'
    }
    It 'read that variable back inside a different module' {
        $r = & "f-$guid"
        $r | Should be 'global variable'
    }
}
