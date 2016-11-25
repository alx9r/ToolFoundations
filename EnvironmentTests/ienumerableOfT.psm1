class a {}
class c {}
function FunctionName {}
function New-Enumerable { ,[SomeEnumerable]::new() }

# the IEnumerable classes
class _SomeEnumerable : System.Collections.IEnumerable {
    [System.Collections.IEnumerator] GetEnumerator () {
        return [_SomeEnumerator]::new()
    }
}
class SomeEnumerable : _SomeEnumerable,System.Collections.Generic.IEnumerable[a]
{
    [System.Collections.Generic.IEnumerator[a]] GetEnumerator ()
    {
        return [SomeEnumerator]::new()
    }
}

# the IEnumerator classes
class _SomeEnumerator : System.Collections.IEnumerator {
    _SomeEnumerator ()
    {
        FunctionName
    }

    [object] get_Current ()
    {
        return [a]::new()
    }

    [bool] MoveNext ()
    {
        return $false
    }

    Reset () {}
    Dispose () {}
}
class SomeEnumerator : _SomeEnumerator,System.Collections.Generic.IEnumerator[a]
{
    SomeEnumerator () : base() {}

    [a] get_Current ()
    {
        return [a]::new()
    }
}

Export-ModuleMember -Function 'New-Enumerable'
