$guid = [guid]::NewGuid().Guid.Replace('-','')

Describe 'alias scope' {
    Context 'availability across pester scriptblocks' {
        It 'set the alias' {
            Set-Alias $guid Out-Null
        }
        It 'the alias in a different it{} block is not available' {
            { Get-Alias $guid -ea Stop } |
                Should throw 'cannot find a matching alias'
        }
    }
    Context 'availability in parent scope' {
        function f1 { Set-Alias $guid Out-Null }
        function f2 { f1; Get-Alias $guid -ea Stop }
        function g1 { Set-Alias $guid Out-Null -Scope 1 }
        function g2 { g1; Get-Alias $guid -ea Stop }
        It 'an alias set in the child scope is not available in the parent scope...' {
            { f2 } |
                Should throw 'cannot find a matching alias'
        }
        It '...unless you specify a -Scope parameter' {
            $r = g2
            $r.Name | Should be $guid
        }
    }
    Context 'availability across module boundary' {
        $module = New-Module "m1-$guid" -ScriptBlock ([scriptblock]::Create( @"
                function g1-$guid { Set-Alias $guid Out-Null -Scope 1 }
                function g2-$guid { g1-$guid; Get-Alias $guid -ea Stop }
                function export-$guid { Export-ModuleMember -Alias $guid }

                Set-Alias l-$guid Out-Null
                Export-ModuleMember -Alias l-$guid -Function *
"@
            ))
        $module | Import-Module -WarningAction SilentlyContinue
        It 'is available to parent when parent is within the same module...' {
            $r = & "g2-$guid"
            $r.Name | Should be $guid
        }
        It '...but not when parent is outside the module...' {
            & "g1-$guid"
            { Get-Alias $guid -ea Stop } |
                Should throw 'cannot find a matching alias'
        }
        It '...unless it is exported...' {
            Get-Alias "l-$guid"
        }
        It '...but not if it is exported after loading the module.' {
            & "export-$guid"
            { Get-Alias $guid -ea Stop } |
                Should throw 'cannot find a matching alias'
        }
    }
}
