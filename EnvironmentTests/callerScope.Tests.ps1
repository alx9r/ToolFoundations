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

Describe 'attempt to surgically import module into caller''s scope using session state' {
    $guidFrag = [guid]::NewGuid().Guid.Split('-')[0]
    $m1 = New-Psm1File m1_$guidFrag {
        function f1 {
            [CmdletBinding()]
            param($Path)
            & $PSCmdlet.SessionState.PSVariable.GetValue('MyInvocation').MyCommand.Module Import-Module $Path
        }
        function g1 {
            [CmdletBinding()]
            param()
            $PSCmdlet.SessionState.PSVariable.GetValue('MyInvocation').MyCommand.Module
        }
    } | Import-Module -PassThru

    $m2 = New-Psm1File m2_$guidFrag {
        Import-Module $args
        function f2 {
            param($Path)
            f1 -Path $Path
        }
        function g2 { g1 }
    } | Import-Module -ArgumentList $m1 -PassThru
    $m3Path = New-Psm1File m3_$guidFrag {
        function f3 { 'function f3' }
    }

    Context 'confirm setup' {
        It 'gets module info from session state' {
            $r = g2
            $r | Should beOfType ([psmoduleinfo])
            $r.Name | Should be m2_$guidFrag
        }
        It 'gets module info from inside module using &' {
            $r = & $m2 Get-Module m1_$guidFrag
            $r | Should beOfType ([psmoduleinfo])
            $r.Name | Should be m1_$guidFrag
        }
    }

    Context 'run test' {
        f2 -Path $m3Path

        It 'module is not imported into caller''s module' {
            $r = & $m2 Get-Module m3_$guidFrag
            $r | Should beNullOrEmpty
        }
    }
}

Describe 'Import-Module -Global' {
    $guidFrag = [guid]::NewGuid().Guid.Split('-')[0]
    $m1Path = New-Psm1File m1_$guidFrag {
        function f1 { 'function f1' }
    }
    $m2Path = New-Psm1Module m2_$guidFrag {
        function f2
        {
            param($Path)
            Import-Module $Path -Global
        }
    }
    $m3 = New-Psm1File m3_$guidFrag {
        Import-Module $args
        function f3 { param($Path) f2 -Path $Path }
    } | Import-Module -ArgumentList $m2Path -PassThru

    $m4 = New-Psm1Module m4_$guidFrag {}

    Context 'before Import-Module -Global' {
        It 'imported module is not available in this scope' {
            $r = Get-Module m1_$guidFrag
            $r | Should beNullOrEmpty
        }
        It 'imported module is not available in unrelated module' {
            $r = & $m4 Get-Module m1_$guidFrag
            $r | Should beNullOrEmpty
        }
    }
    f3 -Path $m1Path
    Context 'after' {
        It 'imported module is available in this scope' {
            $r = Get-Module m1_$guidFrag
            $r | Should beOfType ([psmoduleinfo])
        }
        It 'imported module is available in unrelated module' {
            $r = & $m4 Get-Module m1_$guidFrag
            $r | Should beOfType ([psmoduleinfo])
        }
    }
}
