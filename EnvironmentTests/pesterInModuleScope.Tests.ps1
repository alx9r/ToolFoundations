$guid = [guid]::NewGuid().Guid
$h = @{}
$h.MyInvocation = $MyInvocation
$h.PesterInvokedScript = $h.MyInvocation.Line -match '&\ \$Path\ @Parameters\ @Arguments'

Describe 'invocation method' {
    It "PSScriptRoot: $PSScriptRoot" {}
    It "PSCommandPath: $PSCommandPath" {}
    IT "MyInvocation.Line: $($h.MyInvocation.Line)" {}
    It "PesterInvokedScript: $($h.PesterInvokedScript)" {}
}

Describe 'import one dynamic module from another' {
    It 'create module A' {
        $h.ModuleA = New-Module -Name "ModuleA-$guid" -ScriptBlock (
            [scriptblock]::Create(@"
                function A1-$guid { 'real result of A1' }
                function A2-$guid { "A2 calls A1: `$(A1-$guid)" }
"@
            )
        )
        $h.ModuleA | Import-Module -Force -WarningAction SilentlyContinue
    }
    It 'create module B' {
        $h.ModuleB = New-Module -Name "ModuleB-$guid" -ScriptBlock (
            [scriptblock]::Create(@"
                    Get-Module ModuleA-$guid | Import-Module  -WarningAction SilentlyContinue
                    function B-$guid { "B calls A1: `$(A1-$guid)" }
"@
            )
        )
        $h.ModuleB | Import-Module -Force -WarningAction SilentlyContinue
    }
    It 'command in inner module works' {
        $r = & "A1-$guid"
        $r | Should be 'real result of A1'
    }
    It 'command in outer module calls inner module' {
        $r = & "B-$guid"
        $r | Should be 'B Calls A1: real result of A1'
    }
}

# This is hard to test in PowerShell 2 because $guid
# isn't available inside the InModuleScope scriptblock.
if ($PSVersionTable.PSVersion.Major -ge 3)
{
Describe 'effect of InModuleScope' {
    Context 'directly invoke mocked command without InModuleScope' {
        Mock "A1-$guid" { 'mocked result of A1' }

        It 'returns result from mocked function' {
            $r = & "A1-$guid"
            $r | Should be 'mocked result of A1'
        }
    }
    InModuleScope "ModuleA-$guid" {
        Context 'directly invoke mocked command InModuleScope of the command''s module' {
            Mock "A1-$guid" { 'mocked result of A1' }

            It 'returns result from mocked function' {
                $r = & "A1-$guid"
                $r | Should be 'mocked result of A1'
            }
        }
    }
    Context 'indirectly invoke mocked command from another module without InModuleScope' {
        Mock "A1-$guid" { 'mocked result of A1' }

        It 'returns result from real function' {
            $r = & "B-$guid"
            $r | Should be 'B calls A1: real result of A1'
        }
    }
    InModuleScope "ModuleA-$guid" {
        Context 'indirectly invoke mocked command from another module InModuleScope of the mocked command''s module' {
            Mock "A1-$guid" { 'mocked result of A1' }

            It 'returns result from real function' {
                $r = & "B-$guid"
                $r | Should be 'B calls A1: real result of A1'
            }
        }
    }

    if ( $h.PesterInvokedScript )
    {
        InModuleScope "ModuleB-$guid" {
            Context 'mock command of one module InModuleScope of another module' {
                try
                {
                    Mock "A1-$guid" { 'mocked result of A1' }
                }
                catch
                {
                    $h.Exception = $_
                }
                It 'throws CommandNotFoundException (only true when Pester invokes the script)' {
                    $h.Exception.FullyQualifiedErrorId | Should be 'CommandNotFoundException'
                }
            }
        }
    }
    else # the script was probably run directly in the console
    {
        InModuleScope "ModuleB-$guid" {
            Context 'indirectly invoke mocked command from another module InModuleScope of that module' {
                Mock "A1-$guid" { 'mocked result of A1' }

                It 'returns result from mocked function (only works when test script invoked from console)' {
                    $r = & "B-$guid"
                    $r | Should be 'B calls A1: mocked result of A1'
                }
            }
        }
    }
    Context 'indirectly invoke mocked command from mocked command''s module without InModuleScope' {
        Mock "A1-$guid" { 'mocked result of A1' }

        It 'returns result from real function' {
            $r = & "A2-$guid"
            $r | Should be 'A2 calls A1: real result of A1'
        }
    }
    if ( $h.PesterInvokedScript )
    {
        InModuleScope "ModuleA-$guid" {
            Context 'indirectly invoke mocked command from mocked command''s module InModuleScope of the mocked command''s module' {
                Mock "A1-$guid" { 'mocked result of A1' }

                It 'returns result from real function (but only when Pester invokes the test script)' {
                    $r = & "A2-$guid"
                    $r | Should be 'A2 calls A1: real result of A1'
                }
            }
        }
    }
    else # the script was probably run directly in the console
    {
        InModuleScope "ModuleA-$guid" {
            Context 'indirectly invoke mocked command from mocked command''s module InModuleScope of the mocked command''s module' {
                Mock "A1-$guid" { 'mocked result of A1' }

                It 'returns result from mocked function (but not when Pester invokes the test script)' {
                    $r = & "A2-$guid"
                    $r | Should be 'A2 calls A1: mocked result of A1'
                }
            }
        }
    }
}
}
