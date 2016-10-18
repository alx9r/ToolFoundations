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
Describe 'explicit casting of $null' {
    It 'int32 casts to 0' {
        [int32]$null | Should be 0
    }
    It 'int casts to 0' {
        [int]$null | Should be 0
    }
    It 'string casts to empty string' {
        [string]$null -eq [string]::Empty | Should be $true
    }
}
Describe 'implicit parameter cast - custom function' {
    function IntParam { param([int]$Integer) $Integer }
    Context 'interrogate function' {
        It 'parameter type is int or int32' {
            if ( $PSVersionTable.PSVersion.Major -ge 3 )
            {
                (Get-Help IntParam).parameters.parameter |
                    ? {$_.Name -eq 'Integer'} |
                    % {$_.parametervalue } |
                    Should be 'int'
            }
            else
            {
                Get-Help IntParam | Should match int32
            }
        }
    }
    Context 'normal invocation' {
        It 'accepts an integer' {
            IntParam 2 | Should be 2
        }
        if ( $PSVersionTable.PSVersion.Major -ge 3 )
        {
            It 'converts $null to 0' {
                IntParam $null | Should be 0
            }
        }
        else
        {
            It 'leaves $null as $null' {
                IntParam $null | Should beNullOrEmpty
            }
        }
    }
    Context 'invocation using &' {
        It 'accepts an integer' {
            & 'IntParam' 2 | Should be 2
        }
        if ( $PSVersionTable.PSVersion.Major -ge 3 )
        {
            It 'converts $null to 0' {
                & 'IntParam' $null | Should be 0
            }
        }
        else
        {
            It 'leaves $null as $null' {
                & 'IntParam' $null | Should beNullOrEmpty
            }
        }
    }
}
Describe 'implicit parameter cast - builtin function' {
    if (
        @(3,4) -contains $PSVersionTable.PSVersion.Major -or
        (
            $PSVersionTable.PSVersion.Major -eq 5 -and
            $PSVersionTable.PSVersion.Minor -eq 0 -and
            $PSVersionTable.PSVersion.Build -lt 10586
        )
    )
    {
        Context 'interrogate function' {
            It 'parameter type is int*' {
                (Get-Help Select-Object).parameters.parameter |
                    ? {$_.Name -eq 'First'} |
                    % {$_.parametervalue } |
                    Should match 'int'
            }
        }
    }
    elseif ( $PSVersionTable.PSVersion.Major -ge 5 )
    {
        Context 'interrogate function' {
            It 'parameter type is int*' {
                (Get-Help Select-Object).parameters.parameter |
                    ? {$_.Name -eq 'First'} |
                    % {$_.parametervalue } |
                    Should match 'SwitchParameter'
            }
        }
    }

    Context 'normal invocation' {
        It 'accepts an integer' {
            2,3 | Select-Object -First 1 | Should be 2
        }

        It 'throws on conversion $null to 0' {
            { 2,3 | Select-Object -First $null } | Should throw 'The argument is null, empty'
        }
    }
    Context 'using &' {
        It 'accepts an integer' {
            2,3 | & 'Select-Object' -First 1 | Should be 2
        }

        It 'throws on conversion $null to 0' {
            { 2,3 | & 'Select-Object' -First $null } | Should throw 'The argument is null, empty'
        }
    }
}

