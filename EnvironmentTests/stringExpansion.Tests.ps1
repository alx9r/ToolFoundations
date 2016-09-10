Describe 'string expansion using $ExecutionContext' {
    $psver = $PSVersionTable.PSVersion.Major
    $psVintage = @{
        1 = 'old'
        2 = 'old'
        3 = 'middle'
        4 = 'middle'
        5 = 'modern'
    }.$psver
    It '.ExpandString() expands normal string' {
        $v = 'variable'
        $r = $ExecutionContext.InvokeCommand.ExpandString('expanded $v')
        $r | Should be 'expanded variable'
    }
    It '.ExpandString() expands variable inside quotes' {
        $v = 'variable'
        $r = $ExecutionContext.InvokeCommand.ExpandString('expanded "$v"')
        $r | Should be @{
            old    = 'expanded variable'
            middle = 'expanded "variable"'
            modern = 'expanded "variable"'
        }.$psVintage
    }
    It 'double quotes can expand $($o.V)' {
        $o = New-Object psobject -Property @{V = 'variable'}
        $r = "expanded $($o.V)"
        $r | Should be 'expanded variable'
    }
    if ( 'old','modern' -contains $psVintage )
    {
        It ".ExpandString() expands `$(`$o.V) in PowerShell $psver" {
            $o = New-Object psobject -Property @{V = 'variable'}
            $r = $ExecutionContext.InvokeCommand.ExpandString('expanded $($o.V)')
            $r | Should be 'expanded variable'
        }
    }
    if ( 'middle' -contains $psVintage )
    {
        It ".ExpandString() throws when expanding `$(`$o.V) in PowerShel $psver" {
            $o = New-Object psobject -Property @{V = 'variable'}
            try
            {
                $ExecutionContext.InvokeCommand.ExpandString('expanded $($o.V)')
            }
            catch [System.NullReferenceException]
            {
                $threw = $true
            }
            $threw | Should be $true
        }
    }
    It '.ExpandString() doesn''t throw when expanding empty $()' {
        $r = $ExecutionContext.InvokeCommand.ExpandString('expanded $()')
        $r | Should be @{
            old = 'expanded $'
            middle = 'expanded '
            modern = 'expanded '
        }.$psVintage
    }
    It '.ExpandString() can expand $($v)' {
        $v = 'variable'
        $r = $ExecutionContext.InvokeCommand.ExpandString('expanded $($v)')
        $r | Should be 'expanded variable'
    }
    if ( 'old','modern' -contains $psVintage )
    {
        It ".ExpandString() expands `$(Get-Variable) in PowerShell $psver" {
            $v = 'variable'
            Get-Variable v -ValueOnly | Should be 'variable'
            $r = $ExecutionContext.InvokeCommand.ExpandString('expanded $(Get-Variable v -ValueOnly)')
            $r | Should be 'expanded variable'
        }
    }
    if ( 'middle' -contains $psVintage )
    {
        It ".ExpandString() throws when expanding `$(Get-Variable) in PowerShell $psver" {
            $v = 'variable'
            Get-Variable v -ValueOnly | Should be 'variable'
            try
            {
                $ExecutionContext.InvokeCommand.ExpandString('expanded $(Get-Variable v -ValueOnly)')
            }
            catch [System.NullReferenceException]
            {
                $threw = $true
            }
            $threw | Should be $true
        }
    }
}

