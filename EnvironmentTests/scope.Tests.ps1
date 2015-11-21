Describe 'variable scope' {
    Context 'inherit variable from ancestor.' {
        function f1 {return @{f1 = $someVar}}
        function f2 {$r = f1; $r.f2 = $someVar; return $r}
        function f3 {$r = f2; $r.f3 = $someVar; return $r}

        It 'inherits the ancestor''s scope.' {
            $someVar = 'a'

            $r = f3

            $r.f1 | Should be 'a'
            $r.f2 | Should be 'a'
            $r.f3 | Should be 'a'
        }
    }
    Context 'modify inherited variable.' {
        function f1 {$someVar = 'f1 value'; return @{f1 = $someVar}}
        function f2 {$someVar = 'f2 value'; $r = f1; $r.f2 = $someVar; return $r}
        function f3 {$someVar = 'f3 value'; $r = f2; $r.f3 = $someVar; return $r}

        It 'modifies the local scope.' {
            $someVar = 'a'

            $r = f3

            $r.f1 | Should be 'f1 value'
            $r.f2 | Should be 'f2 value'
            $r.f3 | Should be 'f3 value'
        }
    }
    Context 'modify inherited variable.' {
        function f1 {$someVar = 'f1 value'; return @{f1 = $someVar}}
        function f2 {$r = f1; $r.f2 = $someVar; return $r}
        function f3 {$r = f2; $r.f3 = $someVar; return $r}

        It 'modifies only the local scope. (1)' {
            $someVar = 'a'

            $r = f3

            $r.f1 | Should be 'f1 value'
            $r.f2 | Should be 'a'
            $r.f3 | Should be 'a'
        }
    }
    Context 'modify inherited variable.' {
        function f1 {$someVar = 'f1 value'; return @{f1 = $someVar}}
        function f2 {$someVar = 'f2 value'; $r = f1; $r.f2 = $someVar; return $r}
        function f3 {$r = f2; $r.f3 = $someVar; return $r}

        It 'modifies only the local scope. (2)' {
            $someVar = 'a'

            $r = f3

            $r.f1 | Should be 'f1 value'
            $r.f2 | Should be 'f2 value'
            $r.f3 | Should be 'a'
        }
    }
}
Describe 'preference variable scope' {
    Context 'inherit variable from ancestor.' {
        function f1 {return @{f1 = $VerbosePreference}}
        function f2 {$r = f1; $r.f2 = $VerbosePreference; return $r}
        function f3 {$r = f2; $r.f3 = $VerbosePreference; return $r}

        It 'inherits the ancestor''s scope.' {
            $VerbosePreference = 'Stop'

            $r = f3

            $r.f1 | Should be 'Stop'
            $r.f2 | Should be 'Stop'
            $r.f3 | Should be 'Stop'
        }
    }
    Context 'inherit variable from ancestor from inside module.' {
        $module = New-Module -ScriptBlock {
            function f {return $VerbosePreference}
        }

        It 'does not inherit the ancestor''s scope.' {
            $VerbosePreference = 'Stop'

            $r = f

            $r | Should be 'SilentlyContinue'
        }
    }
    Context 'modify inherited variable.' {
        function f1 {$VerbosePreference = 'Ignore'; return @{f1 = $VerbosePreference}}
        function f2 {$VerbosePreference = 'Suspend'; $r = f1; $r.f2 = $VerbosePreference; return $r}
        function f3 {$VerbosePreference = 'Continue'; $r = f2; $r.f3 = $VerbosePreference; return $r}

        It 'modifies the local scope.' {
            $VerbosePreference = 'Stop'

            $r = f3

            $r.f1 | Should be 'Ignore'
            $r.f2 | Should be 'Suspend'
            $r.f3 | Should be 'Continue'
        }
    }
    Context 'modify inherited variable.' {
        function f1 {$VerbosePreference = 'Ignore'; return @{f1 = $VerbosePreference}}
        function f2 {$r = f1; $r.f2 = $VerbosePreference; return $r}
        function f3 {$r = f2; $r.f3 = $VerbosePreference; return $r}

        It 'modifies only the local scope. (1)' {
            $VerbosePreference = 'Stop'

            $r = f3

            $r.f1 | Should be 'Ignore'
            $r.f2 | Should be 'Stop'
            $r.f3 | Should be 'Stop'
        }
    }
    Context 'modify inherited variable.' {
        function f1 {$VerbosePreference = 'Ignore'; return @{f1 = $VerbosePreference}}
        function f2 {$VerbosePreference = 'Suspend'; $r = f1; $r.f2 = $VerbosePreference; return $r}
        function f3 {$r = f2; $r.f3 = $VerbosePreference; return $r}

        It 'modifies only the local scope. (2)' {
            $VerbosePreference = 'Stop'

            $r = f3

            $r.f1 | Should be 'Ignore'
            $r.f2 | Should be 'Suspend'
            $r.f3 | Should be 'Stop'
        }
    }
}
Describe 'closures' {
    It 'uses the variable value in the parent scope. {}'  {
        $sb = {
            $varNotInSb
        }
        $varNotInSb = 'value1'

        & $sb | Should be 'value1'
    }
    It 'uses the variable value in the parent scope. ([scriptblock]::Create)' {
        $sb = [scriptblock]::Create(
            '$varNotInSb'
        )
        $varNotInSb = 'value1'

        & $sb | Should be 'value1'
    }
    It 'uses the variable value captured by the closure.' {
        $sb = {
            $varNotinSb
        }
        $varNotInSb = 'value1'
        $sb = $sb.GetNewClosure()
        $varNotInSb = 'value2'

        & $sb | Should be 'value1'
    }
    It 'captures a hashtable...' {
        $sb = {
            $htNotInSb
        }
        $htNotInSb = @{a='value1'}
        $sb = $sb.GetNewClosure()
        $htNotInSb = @{a='value1';b='value2'}

        (& $sb).Count | Should be 1
    }
    It '...but does not capture its values.' {
        $sb = {
            $htNotInSb.a
        }
        $htNotInSb = @{a='value1'}
        $sb = $sb.GetNewClosure()
        $htNotInSb.a = 'value2'

        & $sb | Should be 'value2'
    }
}
Describe 'lambdas and the .NET framework' {
    It 'scriptblocks work as lambda in the .NET framework.' {
        $r = ([regex]'apple').Replace('this contains apple',{'banana'})
        $r | Should be 'this contains banana'
    }
    It 'the scriptblock receives the match as a parameter.' {
        $r = ([regex]'apple').Replace('this contains apple',{param($m) ([string]$m).ToUpper()})
        $r | Should beExactly 'this contains APPLE'
    }
    It 'the scriptblock can use a captured string variable.' {
        $color = 'red'
        $r = ([regex]'apple').Replace('this contains apple',{param($m) "$color $m"})
        $r | Should be 'this contains red apple'
    }
    It 'the scriptblock can use a captured hashtable.' {
        $h = @{ color = 'red' }
        $r = ([regex]'apple').Replace('this contains apple',{param($m) "$($h.color) $m"})
        $r | Should be 'this contains red apple'
    }
    It 'the scriptblock can pass the match as a key to the captured hashtable.' {
        $colors = @{
            apple = 'red'
        }
        $r = ([regex]'apple').Replace('this contains apple',{param($m) "$($colors."$m") $m"})
        $r | Should be 'this contains red apple'
    }
}
