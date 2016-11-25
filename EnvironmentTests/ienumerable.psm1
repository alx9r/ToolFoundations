class a {}
class c {}
function FunctionName {}
function New-Enumerable { ,[SomeEnumerable]::new() }

class SomeEnumerable : System.Collections.IEnumerable {
    [System.Collections.IEnumerator] GetEnumerator () {
        return [SomeEnumerator]::new()
    }
}

class SomeEnumerator : System.Collections.IEnumerator {
    SomeEnumerator ()
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

Export-ModuleMember -Function 'New-Enumerable'
