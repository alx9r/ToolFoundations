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