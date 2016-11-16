Describe 'non-generic IEnumerable' {
    Context 'requires GetEnumerator method' {
        It 'throws without' {
            { iex 'class c : System.Collections.IEnumerable {}' } |
                Should throw "Method 'GetEnumerator'"
        }
        It 'implementing method satisfies interpreter' {
            class c : System.Collections.IEnumerable {
                [System.Collections.IEnumerator] GetEnumerator () {
                    return @().GetEnumerator()
                }
            }
        }
    }
}
Describe 'non-generic IEnumerator' {
    Context 'requires implementations' {
        It 'method MoveNext' {
            { iex @'
                class e : System.Collections.IEnumerator {
                    # [object] get_Current () { return '' }
                    # [bool] MoveNext () {return $true}
                    # Reset () {}
                }
'@
            } |
                Should throw "Method 'MoveNext'"
        }
        It 'method get_Current' {
            { iex @'
                class e : System.Collections.IEnumerator {
                    # [object] get_Current () { return '' }
                    [bool] MoveNext () {return $true}
                    # Reset () {}
                }
'@
            } |
                Should throw "Method 'get_Current'"
        }
        It 'method Reset' {
            { iex @'
                class e : System.Collections.IEnumerator {
                    [object] get_Current () { return '' }
                    [bool] MoveNext () {return $true}
                    # Reset () {}
                }
'@
            } |
                Should throw "Method 'Reset'"
        }
        It 'complete' {
            class e : System.Collections.IEnumerator {
                [object] get_Current () { return '' }
                [bool] MoveNext () {return $true}
                Reset () {}
            }
        }
    }
}
Describe 'generic IEnumerator' {
    # https://gist.github.com/Jaykul/dfc355598e0f233c8c7f288295f7bb56
    class _e : System.Collections.IEnumerator {
        [object] get_Current () { return 'non-generic' }
        [bool] MoveNext () { return $true }
        Reset () {}
    }
    class __e : System.Collections.IEnumerator {
        [object] get_Current () { return 'non-generic' }
        [bool] MoveNext () { return $true }
        Reset () {}
        Dispose () {}
    }
    It 'requires Dispose()' {
        { iex @'
        class e : _e, System.Collections.Generic.IEnumerator[string] {
            [string] get_Current () {return 'generic'}
        }
'@
        } |
            Should throw "Method 'Dispose'"
    }
    It 'works once Dispose() is implemented' {
        class e : _e, System.Collections.Generic.IEnumerator[string] {
            [string] get_Current () {return 'generic'}
            Dispose() {}
        }
    }
    It 'Dispose() can be implemented in the base class' {
        class e : __e, System.Collections.Generic.IEnumerator[string] {
            [string] get_Current () {return 'generic'}
            Dispose() {}
        }
    }
}
Describe 'non-generic IEnumerator implementation' {
    # https://msdn.microsoft.com/en-us/library/system.collections.ienumerator(v=vs.110).aspx
    class e : System.Collections.IEnumerator {
        $a = 'a','b'
        [Nullable[int]] $i
        [object] get_Current () {
            if ( $null -eq $this.i )
            {
                return $null
            }
            if ( $this.i -gt 1 )
            {
                throw 'enumerator past end'
                return $null
            }
            return $this.a[$this.i]
        }
        [bool] MoveNext () {
            if ( $this.i -ge 1 )
            {
                $this.i++
                return $false
            }
            if ( $null -eq $this.i )
            {
                $this.i = 0
                return $true
            }
            $this.i++
            return $true
        }
        Reset () {
            $this.i = $null
        }
    }
    $e = [e]::new()
    Context 'manual invocation' {
        It 'i is null to start' {
            $e.i | Should beNullOrEmpty
        }
        It 'Current returns null' {
            $e.Current | Should be $null
        }
        It 'MoveNext() returns true' {
            $r = $e.MoveNext()
            $r | Should beOfType bool
            $r | Should be $true
        }
        It 'Current returns a' {
            $r = $e.Current
            $r | Should be 'a'
        }
        It 'MoveNext() returns true' {
            $r = $e.MoveNext()
            $r | Should beOfType bool
            $r | Should be $true
        }
        It 'Current returns b' {
            $r = $e.Current
            $r | Should be 'b'
        }
        It 'MoveNext() returns false' {
            $r = $e.MoveNext()
            $r | Should beOfType bool
            $r | Should be $false
        }
        It 'getting Current does not throw an exception' {
            $e.Current
        }
        It 'getting Current returns null' {
            $r = $e.Current
            $r | Should beNullOrEmpty
        }
        It 'get_Current() throws exception' {
            { $e.get_Current() } |
                Should throw 'enumerator past end'
        }
        It 'Reset()' {
            $e.Reset()
        }
        It 'i is null again' {
            $e.i | Should beNullOrEmpty
        }
    }
}

Describe 'PowerShell translation of Jon Skeet Example using Jaykul''s inheritance technique' {
    # see listing 3.10 of Jon Skeet's C# in Depth, 2nd Edition
    # https://gist.github.com/Jaykul/dfc355598e0f233c8c7f288295f7bb56
    class _CountingEnumerable : System.Collections.IEnumerable
    {
        [System.Collections.IEnumerator] GetEnumerator()
        {
            return [_CountingEnumerator]::new()
        }
    }
    class CountingEnumerable : _CountingEnumerable,System.Collections.Generic.IEnumerable[int]
    {
        [System.Collections.Generic.IEnumerator[int]] GetEnumerator()
        {
            return [CountingEnumerator]::new()
        }
    }
    class _CountingEnumerator : System.Collections.IEnumerator
    {
        [int] $Current = -1
        static [string] $which_get_Current

        [bool] MoveNext()
        {
            $this.Current ++
            return $this.Current -lt 10
        }

        [object] _get_Current()
        {
            return $this.Current
        }

        [object] get_Current ()
        {
            [_CountingEnumerator]::which_get_Current = 'non-generic'
            return $this._get_Current()
        }

        Reset() {}
        Dispose() {}
    }
    class CountingEnumerator : _CountingEnumerator,System.Collections.Generic.IEnumerator[int]
    {
        [int] get_Current ()
        {
            [_CountingEnumerator]::which_get_Current = 'generic'
            return ([_CountingEnumerator]$this)._get_Current()
        }
    }
    Context 'non-generic' {
        It 'pipeline correctly consumes enumerator' {
            $r = [_CountingEnumerator]::new() | % {$_}
            $r.Count | Should be 10
            $r[9] | Should be 9
        }
        It 'invoked non-generic get_Current' {
            [_CountingEnumerator]::which_get_Current |
                Should be 'non-generic'
        }
        It 'pipeline correctly consumes enumerable' {
            $r = [_CountingEnumerable]::new() | % {$_}
            $r.Count | Should be 10
            $r[9] | Should be 9
        }
        It 'invoked non-generic get_Current' {
            [_CountingEnumerator]::which_get_Current |
                Should be 'non-generic'
        }
        It 'throws when converting enumerable to generic list using constructor' {
            { [System.Collections.Generic.List[int]]::new([_CountingEnumerable]::new()) } |
                Should throw 'Cannot find an overload'
        }
        It 'throws when converting enumerable to generic list by casting' {
            { [System.Collections.Generic.List[int]] $r = [_CountingEnumerable]::new() } |
                Should throw 'Cannot convert'
        }
    }
    Context 'generic' {
        It 'pipeline correctly consumes enumerator' {
            $r = [CountingEnumerator]::new() | % {$_}
            $r.Count | Should be 10
            $r[9] | Should be 9
        }
        It 'invoked non-generic get_Current' {
            [_CountingEnumerator]::which_get_Current |
                Should be 'non-generic'
        }
        It 'pipeline correctly consumes enumerable' {
            $r = [CountingEnumerable]::new() | % {$_}
            $r.Count | Should be 10
            $r[9] | Should be 9
        }
        It 'invoked non-generic get_Current' {
            [_CountingEnumerator]::which_get_Current |
                Should be 'non-generic'
        }
        It 'correct counts using foreach loop' {
            $j = 0
            foreach ( $i in [CountingEnumerable]::new() )
            {
                $i | Should be $j
                $j ++
            }
            $j | Should be 10
        }
        It 'invoked non-generic get_Current' {
            [_CountingEnumerator]::which_get_Current |
                Should be 'non-generic'
        }
        It 'converts enumerable to generic list using constructor' {
            $r = [System.Collections.Generic.List[int]]::new([CountingEnumerable]::new())
            $r.Count | Should be 10
            $r[9] | Should be 9
        }
        It 'invoked generic get_Current' {
            [_CountingEnumerator]::which_get_Current |
                Should be 'generic'
        }
        It 'converts enumerable to generic list using casting' {
            [System.Collections.Generic.List[int]] $r = [CountingEnumerable]::new()
            $r.Count | Should be 10
            $r[9] | Should be 9
        }
        It 'invoked generic get_Current' {
            [_CountingEnumerator]::which_get_Current |
                Should be 'generic'
        }
        It 'can be manually invoked' {
            $eable = [CountingEnumerable]::new()
            $eator = $eable.GetEnumerator()
            $eator.Current | Should be -1
            $eator.MoveNext() | Should be $true
            $eator.Current | Should be 0
        }
        It 'invoked generic get_Current' {
            [_CountingEnumerator]::which_get_Current |
                Should be 'generic'
        }
    }
}

Describe 'IEnumerable<T> emitted from module' {
    $module = New-Module 'ienumerables' {
        class _CountingEnumerable : System.Collections.IEnumerable
        {
            [System.Collections.IEnumerator] GetEnumerator()
            {
                return [_CountingEnumerator]::new()
            }
        }
        class CountingEnumerable : _CountingEnumerable,System.Collections.Generic.IEnumerable[int]
        {
            [System.Collections.Generic.IEnumerator[int]] GetEnumerator()
            {
                return [CountingEnumerator]::new()
            }
        }
        class _CountingEnumerator : System.Collections.IEnumerator
        {
            [int] $Current = -1

            [bool] MoveNext()
            {
                $this.Current ++
                return $this.Current -lt 10
            }

            [object] get_Current ()
            {
                return $this.Current
            }

            Reset() {}
            Dispose() {}
        }
        class CountingEnumerator : _CountingEnumerator,System.Collections.Generic.IEnumerator[int]
        {
            [int] get_Current ()
            {
                return $this.Current
            }
        }
        function New-CountingEnumerable { return ,[CountingEnumerable]::new() }
    }
    It 'New-' {
        $r = New-CountingEnumerable
        $r.GetType().Name | Should be 'CountingEnumerable'
    }
    It 'correctly counts using foreach loop' {
        $counter = New-CountingEnumerable
        $j = 0
        foreach ( $i in $counter )
        {
            $i | Should be $j
            $j ++
        }
        $j | Should be 10
    }
}

Describe 'IEnumerable<T> emitted from module where T is a powershell class' {
    $module = New-Module 'ienumerables' {
        class c { $i=0 }
        class _CountingEnumerable : System.Collections.IEnumerable
        {
            [System.Collections.IEnumerator] GetEnumerator()
            {
                return [_CountingEnumerator]::new()
            }
        }
        class CountingEnumerable : _CountingEnumerable,System.Collections.Generic.IEnumerable[c]
        {
            [System.Collections.Generic.IEnumerator[c]] GetEnumerator()
            {
                return [CountingEnumerator]::new()
            }
        }
        class _CountingEnumerator : System.Collections.IEnumerator
        {
            [int] $Current = -1

            [bool] MoveNext()
            {
                $this.Current ++
                return $this.Current -lt 10
            }

            [object] get_Current ()
            {
                $object = [c]::new()
                $object.i = $this.Current
                return $object
            }

            Reset() {}
            Dispose() {}
        }
        class CountingEnumerator : _CountingEnumerator,System.Collections.Generic.IEnumerator[c]
        {
            [c] get_Current ()
            {
                return $this.Current
            }
        }
        function New-CountingEnumerable { return ,[CountingEnumerable]::new() }
    }
    It 'New-' {
        $r = New-CountingEnumerable
        $r.GetType().Name | Should be 'CountingEnumerable'
    }
    It 'correctly counts using foreach loop' {
        $counter = New-CountingEnumerable
        $j = 0
        foreach ( $c in $counter )
        {
            $c.i | Should be $j
            $j ++
        }
        $j | Should be 10
    }
}
