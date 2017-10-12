Describe 'script module access of variable in caller''s scope using SessionState' {
    $m1 = New-Module m1 {
        function Get-CallerVariable {
            param([Parameter(Position=1)][string]$Name)
            $PSCmdlet.SessionState.PSVariable.GetValue($Name)
        }
        function Set-CallerVariable {
            param(
                [Parameter(ValueFromPipeline=$true)][string]$Value,
                [Parameter(Position=1)]$Name
            )
            process { $PSCmdlet.SessionState.PSVariable.Set($Name,$Value)}
        }
        function f1 {
            $l = 'caller value'
            Get-CallerVariable l
        }
        function g1 {
            $l = 'original value'
            'new value' | Set-CallerVariable l
            $l
        }
    } | Import-Module -PassThru

    New-Module m2 {
        function f2 {
            $l = 'caller value'
            Get-CallerVariable l
        }
        function g2 {
            $l = 'original value'
            'new value' | Set-CallerVariable l
            $l
        }
    } | Import-Module

    Context 'from outside module scope' {
        It 'gets variable' {
            $l = 'caller value'
            $r = Get-CallerVariable l
            $r | Should be 'caller value'
        }
        It 'sets variable' {
            $l = 'original value'
            'new value' | Set-CallerVariable l
            $l | Should be 'new value'
        }
    }
    Context 'from same module' {
        It 'gets variable' {
            $r = f1
            $r | Should be 'caller value'
        }
        It 'does not set variable' {
            $r = g1
            $r | Should be 'original value'
        }
    }
    Context 'from another module' {
        It 'gets variable' {
            $r = f2
            $r | Should be 'caller value'
        }
        It 'does not set variable' {
            $r = g2
            $r | Should be 'new value'
        }
    }
}
