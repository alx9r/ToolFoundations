<#
This tests that a variable defined in global scope in a test
script is accessible from inside a module under test.
#>
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
