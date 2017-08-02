<#
This file tests the circumstances required for mocks to work.

# Part 1
Question: When are mocks and when are real functions called?

Test Method:
The first part of this file tests whether a real or mocked function
will be called depending on the following:
 - whether the mocked function is called inside or outside a module
 - whether a call to the mocked function is subsequent to a callstack
   that originated inside or outside an InModuleScope{} block
 - whether the call is InModuleScope{} of the module where the mocked
   function is defined or the module where the mocked function is
   called.

Answer:
In order for a mock to be called, the mock and the test must be inside
InModuleScope{} for the module under test.


# Part 2
Question: Is importing the module of the mocked function important?

Test Method:
The second part of this file tests whether a testing using mocks works
depending on the following:
 - whether the mock and test is invoked inside or outside InModuleScope{}
 - whether the script is invoked by Pester or in ISE using F5
 - whether the module where the mocked function is defined is imported
   in the module under test.

Answer:
If the mocked function is defined in a different module from the module
under test, the module where the mocked function is defined must be explicitly
imported InModuleScope of the module under test.
#>

$guid = [guid]::NewGuid().Guid
$h = @{}
$h.MyInvocation = $MyInvocation
$h.DirectlyInvokedScript = -not [bool]$h.MyInvocation.Line

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
    It 'create module C' {
        $h.ModuleC = New-Module -Name "ModuleC-$guid" -ScriptBlock (
            [scriptblock]::Create("function C-$guid { `"C calls A1: `$(A1-$guid)`" }" )
        )
        $h.ModuleC | Import-Module -Force -WarningAction SilentlyContinue
    }
    It 'command in inner module works' {
        $r = & "A1-$guid"
        $r | Should be 'real result of A1'
    }
    It 'command in outer module calls inner module' {
        $r = & "B-$guid"
        $r | Should be 'B Calls A1: real result of A1'
    }
    It 'command in outer module calls inner module even though inner module is not imported' {
        $r = & "C-$guid"
        $r | Should be 'C Calls A1: real result of A1'
    }
}

Describe 'effect of InModuleScope on variable accessibility' {
    Context 'outside InModuleScope' {
        It 'variable defined in this script is accessible here' {
            Get-Variable guid | Should not beNullOrEmpty
        }
    }
    if ( $h.DirectlyInvokedScript )
    {
        InModuleScope "ModuleA-$guid" {
            Context 'inside InModuleScope' {
                It 'variable defined in this script is accessible here (but not when Pester invokes the script)' {
                    Get-Variable guid | Should not beNullOrEmpty
                }
            }
        }
    }
    else
    {
        InModuleScope "ModuleA-$guid" {
            Context 'inside InModuleScope' {
                It 'variable defined in this script is not accessible here (when Pester invokes the script)' {
                    { Get-Variable guid -ea Stop } |
                        Should throw 'Cannot find a variable'
                }
            }
        }
    }
    Context 'use TestDrive to pass value to inside InModuleScope' {
        It 'set TestDrive file contents' {
            $guid | Set-Content 'TestDrive:\guid.txt'
        }
        It 'get TestDrive contents outside InModuleScope' {
            $r = Get-Content 'TestDrive:\guid.txt'
            $r | Should be $guid
        }
        InModuleScope "ModuleA-$guid" {
            It 'retrieve TestDrive contents inside InModuleScope' {
                $r = Get-Content 'TestDrive:\guid.txt'
                $r | Test-ValidGuidString -ea SilentlyContinue | Should be $true
            }
            It 'assign TestDrive file contents to a variable inside InModuleScope' {
                $guid = Get-Content 'TestDrive:\guid.txt'
            }
        }
    }
    Context 'persistence of variables set inside InModuleScope' {
        if ( $h.DirectlyInvokedScript )
        {
            InModuleScope "ModuleA-$guid" {
                It 'variable persists across Contexts (when script is invoked directly)' {
                    Get-Variable guid | Should not beNullOrEmpty
                }
            }
        }
        else
        {
            InModuleScope "ModuleA-$guid" {
                It 'variable does not persist across Contexts (when Pester invokes the script)' {
                    { Get-Variable guid -ea Stop } |
                            Should throw 'Cannot find a variable'
                }
            }
        }
    }
}
Describe 'effect of InModuleScope on whether a mock or real command is invoked' {
    It 'set TestDrive file contents' {
        $guid | Set-Content 'TestDrive:\guid.txt'
    }
    Context 'directly invoke mocked command without InModuleScope' {
        Mock "A1-$guid" { 'mocked result of A1' }

        It 'returns result from mocked function' {
            $r = & "A1-$guid"
            $r | Should be 'mocked result of A1'
        }
    }
    InModuleScope "ModuleA-$guid" {
        $guid = Get-Content 'TestDrive:\guid.txt'
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
        if ( $h.DirectlyInvokedScript )
        {
            It 'returns result from mock (when script invoked directly)' {
                $r = & "B-$guid"
                $r | Should be 'B calls A1: mocked result of A1'
            }
        }
        else
        {
            It 'returns result from real function (when script invoked by Pester)' {
                $r = & "B-$guid"
                $r | Should be 'B calls A1: real result of A1'
            }
        }
    }
    InModuleScope "ModuleA-$guid" {
        $guid = Get-Content 'TestDrive:\guid.txt'
        Context 'indirectly invoke mocked command from another module InModuleScope of the mocked command''s module' {
            Mock "A1-$guid" { 'mocked result of A1' }

            It 'returns result from real function' {
                $r = & "B-$guid"
                $r | Should be 'B calls A1: real result of A1'
            }
        }
    }
    InModuleScope "ModuleB-$guid" {
        $guid = Get-Content 'TestDrive:\guid.txt'
        Context 'indirectly invoke mocked command from another module InModuleScope of that module' {
            Mock "A1-$guid" { 'mocked result of A1' }

            It 'returns result from mocked function' {
                $r = & "B-$guid"
                $r | Should be 'B calls A1: mocked result of A1'
            }
        }
    }
    Context 'indirectly invoke mocked command from mocked command''s module without InModuleScope' {
        Mock "A1-$guid" { 'mocked result of A1' }
        if ( $h.DirectlyInvokedScript )
        {
            It 'returns result from mock (when scripted invoked directly)' {
                $r = & "A2-$guid"
                $r | Should be 'A2 calls A1: mocked result of A1'
            }
        }
        else
        {
            It 'returns result from real function (when scripted invoked by Pester)' {
                $r = & "A2-$guid"
                $r | Should be 'A2 calls A1: real result of A1'
            }
        }
    }
    InModuleScope "ModuleA-$guid" {
        $guid = Get-Content 'TestDrive:\guid.txt'
        Context 'indirectly invoke mocked command from mocked command''s module InModuleScope of the mocked command''s module' {
            Mock "A1-$guid" { 'mocked result of A1' }

            It 'returns result from mocked function' {
                $r = & "A2-$guid"
                $r | Should be 'A2 calls A1: mocked result of A1'
            }
        }
    }
}
Describe 'effect of not importing module inside module that invokes mocked command' {
    It 'set TestDrive file contents' {
        $guid | Set-Content 'TestDrive:\guid.txt'
    }
    Context 'indirectly invoke mocked command from another non-importing module without InModuleScope' {
        Mock "A1-$guid" { 'mocked result of A1' }
        if ( $h.DirectlyInvokedScript )
        {
            It 'returns result from mock (when script invoked directly)' {
                $r = & "C-$guid"
                $r | Should be 'C calls A1: mocked result of A1'
            }
        }
        else
        {
            It 'returns result from real function (when script invoked by Pester)' {
                $r = & "C-$guid"
                $r | Should be 'C calls A1: real result of A1'
            }
        }
    }
    InModuleScope "ModuleA-$guid" {
        $guid = Get-Content 'TestDrive:\guid.txt'
        Context 'indirectly invoke mocked command from another non-importing module InModuleScope of the mocked command''s module' {
            Mock "A1-$guid" { 'mocked result of A1' }

            It 'returns result from real function (when script invoked directly)' {
                $r = & "C-$guid"
                $r | Should be 'C calls A1: real result of A1'
            }
        }
    }
    InModuleScope "ModuleC-$guid" {
        $guid = Get-Content 'TestDrive:\guid.txt'
        Context 'indirectly invoke mocked command from another non-importing module InModuleScope of the non-importing module' {
            Mock "A1-$guid" { 'mocked result of A1' }

            It 'returns result from mocked function (when script invoked directly)' {
                $r = & "C-$guid"
                $r | Should be 'C calls A1: mocked result of A1'
            }
        }
    }
}

Remove-Variable 'guid','h'
