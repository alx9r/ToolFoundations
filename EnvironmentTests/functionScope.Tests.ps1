$records = @{}
Describe 'function scope' {
    Context 'inherit function from ancestor.' {
        function g1 {return @{g1 = f3}}
        function g2 {$r = g1; $r.g2 = f3; return $r}
        function g3 {
            function f3 { 'f3' }
            $r = g2; $r.g3 = f3; return $r
        }

        It 'inherits the ancestor''s scope.' {
            $someVar = 'a'

            $r = g3

            $r.g1 | Should be 'f3'
            $r.g2 | Should be 'f3'
            $r.g3 | Should be 'f3'
        }
    }
    Context 'no isolation between modules' {
        $guid = [guid]::NewGuid().Guid
        $module1 = New-Module -Name "Module1-$guid" -ScriptBlock {
            function f1 { 'f1' }
            function Getf2Fromf1 { f2 }
        }
        $module2 = New-Module -Name "Module2-$guid" -ScriptBlock {
            function f2 { 'f2' }
        }
        It 'invoke command implemented in module 1 from this scope' {
            f1 | Should be 'f1'
        }
        It 'invoke command implemented in module 2 from this scope' {
            f2 | Should be 'f2'
        }
        It 'invoke command implemented in module 2 from module 1' {
            Getf2FromF1 | Should be 'f2'
        }
    }
    Context 'naming collision' {
        $guid = [guid]::NewGuid().Guid
        $records.NamingCollisionGuid = $guid
        $module1 = New-Module -Name "Module1-$guid" -ArgumentList $guid -ScriptBlock {
            iex "function f1-$args { 'm1f1-$args' }"
            iex "function f1FromM1-$args { f1-$args }"
        }
        $module2 = New-Module -Name "Module2-$guid" -ArgumentList $guid -ScriptBlock {
            iex "function f1-$args { 'm2f1-$args' }"
            iex "function f1FromM2-$args { f1-$args }"
        }
        It 'invoking command implemented in both module 1 and module 2 invokes module 2''s' {
            & "f1-$guid" | Should be "m2f1-$guid"
        }
        It 'invoking collided name from inside module 1 invokes module 1''s' {
            & "f1FromM1-$guid" | Should be "m1f1-$guid"
        }
        It 'invoking collided name from inside module 2 invokes module 2''s' {
            & "f1FromM2-$guid" | Should be "m2f1-$guid"
        }
        It 'import module 1' {
            $module1 | Import-Module -WarningAction SilentlyContinue
        }
        It 'invoking command implemented in both module 1 and module 2 invokes module 1''s' {
            & "f1-$guid" | Should be "m1f1-$guid"
        }
        It 'invoking collided name from inside module 1 invokes module 1''s' {
            & "f1FromM1-$guid" | Should be "m1f1-$guid"
        }
        It 'invoking collided name from inside module 2 invokes module 2''s' {
            & "f1FromM2-$guid" | Should be "m2f1-$guid"
        }
        It 'import module 2' {
            $module2 | Import-Module -WarningAction SilentlyContinue
        }
        It 'invoking command implemented in both module 1 and module 2 invokes module 2''s' {
            & "f1-$guid" | Should be "m2f1-$guid"
        }
        It 'invoking collided name from inside module 1 invokes module 1''s' {
            & "f1FromM1-$guid" | Should be "m1f1-$guid"
        }
        It 'invoking collided name from inside module 2 invokes module 2''s' {
            & "f1FromM2-$guid" | Should be "m2f1-$guid"
        }
        It 'use fully qualified path to invoke command implemented in module 1' {
            & "Module1-$guid\f1-$guid" | Should be "m1f1-$guid"
        }
        It 'use fully qualified path to invoke command implemented in module 2' {
            & "Module2-$guid\f1-$guid" | Should be "m2f1-$guid"
        }
    }
}
