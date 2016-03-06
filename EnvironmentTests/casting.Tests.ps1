Describe 'cast hashtable to pscustomobject' {
    if ( $PSVersionTable.PSVersion.Major -ge 3 )
    {
        It 'results in pscustomobject in PowerShell 3 or higher' {
            $r = [pscustomobject]@{a=1;b=2}
            $r -is [pscustomobject] | Should be $true
            $r -is [hashtable] | Should be $false
        }
    }
    else
    {
        It 'results in hashtable in PowerShell 2' {
            $r = [pscustomobject]@{a=1;b=2}
            $r -is [hashtable] | Should be $true
        }
    }
    It 'New-Object pscustomobject always works' {
        $r = New-Object pscustomobject -Property @{a=1;b=2}
        $r -is [pscustomobject] | Should be $true
    }
}
Describe 'cast hashtable to psobject' {
    It 'results in hashtable in all versions of PowerShell.' {
        $r = [psobject]@{a=1;b=2}
        $r -is [hashtable] | Should be $true
    }
}
