$psVintage = $PSVersionTable.PSVersion.Major -lt 3 | ?: 'old' 'modern'
Describe 'string expansion using $ExecutionContext' {
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
            modern = 'expanded "variable"'
        }.$psVintage
    }
    It 'double quotes can expand $($o.V)' {
        $o = New-Object psobject -Property @{V = 'variable'}
        $r = "expanded $($o.V)"
        $r | Should be 'expanded variable'
    }
    if ($psVintage -eq 'old' )
    {
        It '.ExpandString() expands $($o.V) in old PowerShell' {
            $o = New-Object psobject -Property @{V = 'variable'}
            $r = $ExecutionContext.InvokeCommand.ExpandString('expanded $($o.V)')
            $r | Should be 'expanded variable'
        }
    }
    if ( $psVintage -eq 'modern' )
    {
        It '.ExpandString() throws when expanding $($o.V) in modern PowerShell' {
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
            modern = 'expanded '
        }.$psVintage
    }
    It '.ExpandString() can expand $($v)' {
        $v = 'variable'
        $r = $ExecutionContext.InvokeCommand.ExpandString('expanded $($v)')
        $r | Should be 'expanded variable'
    }
    if ( $psVintage -eq 'old' )
    {
        It '.ExpandString() throws when expanding $(Get-Variable) in old PowerShell' {
            $v = 'variable'
            Get-Variable v -ValueOnly | Should be 'variable'
            $r = $ExecutionContext.InvokeCommand.ExpandString('expanded $(Get-Variable v -ValueOnly)')
            $r | Should be 'expanded variable'
        }
    }
    if ( $psVintage -eq 'modern' )
    {
        It '.ExpandString() throws when expanding $(Get-Variable) in modern PowerShell' {
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
