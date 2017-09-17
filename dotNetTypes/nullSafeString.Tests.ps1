if ( $PSVersionTable.PSVersion -lt '3.0' )
{
    return
}
Import-Module ToolFoundations -Force

Describe '[NullsafeString]' {
    It 'assignment' {
        [NullsafeString]$r = 'some string'
        $r.GetType() | Should be 'NullSafeString'
        $r.Value | Should be 'some string'
    }
    Context 'as parameter static type' {
        function f { param([NullsafeString]$x) $x }

        It 'null remains null' {
            $r = f -x $null
            $null -eq $r | Should be $true
        }
        It '[string]::empty remains [string]::empty' {
            $r = f -x ([string]::Empty)
            [string]::Empty -eq $r | Should be $true
        }
        It 'value remains value' {
            $r = f -x 'some string'
            $r | Should be 'some string'
        }
    }
    Context 'as argument to [string] parameter' {
        function f { param([string]$x) $x }

        It 'null becomes [string]::empty' {
            $r = f -x $null
            [string]::Empty -eq $r | Should be $true
        }
        It '[string]::empty remains [string]::empty' {
            $r = f -x ([string]::Empty)
            [string]::Empty -eq $r | Should be $true
        }
        It 'value remains value' {
            [NullsafeString]$v = 'some value'
            $r = f -x $v
            $r | Should be 'some value'
        }
    }
    Context 'equation of equals' {
        It 'null with null' {
            [NullsafeString]$r = $null
            $null -eq $r | Should be $true
            $r -eq $null | Should be $true
        }
        It '[string]::empty with [NullsafeString] containing [string]::empty' {
            [string]$s = [string]::Empty
            [NullsafeString]$ns = [string]::Empty
            $s -eq $ns | Should be $true
            $ns -eq $s | Should be $true
        }
        It 'value with [NullsafeString] containing value' {
            [string]$s = 'some value'
            [NullsafeString]$ns = 'some value'
            $s -eq $ns | Should be $true
            $ns -eq $s | Should be $true
        }
    }
    Context 'equation of unequals' {
        It 'null with [NullsafeString] containing value' {
            [NullsafeString]$r = $null
            'value' -eq $r | Should be $false
            $r -eq 'value' | Should be $false
        }
        It 'null with [NullsafeString] containing [string]::empty' {
            [NullsafeString]$ns = [string]::Empty
            $null -eq $ns | Should be $false
            $ns -eq $null | Should be $false
        }
        It 'value with [NullsafeString] containing [string]::empty' {
            [NullsafeString]$ns = [string]::Empty
            'value' -eq $ns | Should be $false
            $ns -eq 'value' | Should be $false
        }
        It '[string]::empty with [NullsafeString] containing value' {
            [NullsafeString]$ns = 'value'
            [string]::Empty -eq $ns | Should be $false
            $ns -eq [string]::Empty | Should be $false
        }
        It 'value with [NullsafeString] containing value' {
            [string]$s = 'some value'
            [NullsafeString]$ns = 'some value'
            $s -eq $ns | Should be $true
            $ns -eq $s | Should be $true
        }
    }
    Context 'conversions' {
        Context 'ChangeType()' {
            It 'to string' {
                [NullSafeString]$nss = 'value'
                [System.Convert]::ChangeType($nss,[string])
            }
            It 'from string throws' {
                $s = 'value'
                { [System.Convert]::ChangeType($s,[NullSafeString]) } |
                    Should throw
            }
        }
        Context 'New-Object' {
            It 'to string throws' {
                [NullSafeString]$nss = 'value'
                { New-Object string($nss) } |
                    Should throw
            }
            It 'from string' {
                $s = 'value'
                New-Object NullSafeString($s)
            }
        }
    }
}
