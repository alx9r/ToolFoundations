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
    Context 'cast to List' {
        $h = @{}
        It 'cast' {
            [System.Collections.Generic.List[string]]$h.List = $e
        }
        It 'list type is correct' {
            ,$h.list | Should beOfType ([System.Collections.Generic.List[string]])
        }
        It 'list count is incorrect' {
            $h.list.Count | Should be 1
        }
    }
}

Describe 'non-generic IEnumerator implementation' {
    class _e : System.Collections.IEnumerator {
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
        Dispose () {}
    }
    class e : _e,System.Collections.Generic.IEnumerator[string] {
        [string] get_Current () {return ([_e]$this).get_Current()}
    }
    $e = [e]::new()

    Context 'cast to List' {
        $h = @{}
        It 'cast' {
            [System.Collections.Generic.List[string]]$h.List = $e
        }
        It 'list type is correct' {
            ,$h.list | Should beOfType ([System.Collections.Generic.List[string]])
        }
        It 'list count is incorrect' {
            $h.list.Count | Should be 1
        }
    }
}