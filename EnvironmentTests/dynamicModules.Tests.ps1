<#
This file tests various aspects of importing, removing and accessibility
of functions in dynamic modules.

Question: Is a dynamic module retrieved by Get-Module?
Answer: Not automatically, but it can be force-imported after which
it is retrieved by Get-Module.

Question: Can a dynamic module be removed or overwritten?
Answer: A dynamic module can be removed after force-importing. A
dynamic module can also be overwritten.  However, a command defined
in a dynamic module continues to be available despite removal or
overwriting of its module.

Question: Can a function in one dynamic module call a function
in another dynamic module?
Answer: Yes, and explicit importing is not required in either
module.
#>

$guid = [guid]::NewGuid().Guid
$h = @{}
Describe 'create a dynamic module' {
    It 'create the module' {
        $h.DynamicModule = New-Module -Name "DynamicModule-$guid" -ScriptBlock (
            [scriptblock]::Create("function f-$guid { 'result of f' }")
        )
        $h.DynamicModule | Should beOfType PSModuleInfo
        $h.DynamicModule.Name | Should be "DynamicModule-$guid"
        $h.DynamicModule.ExportedFunctions."f-$guid" |
            Should not beNullOrEmpty
    }
    It 'the module is not retrieved by Get-Module' {
        $r = Get-Module $h.DynamicModule.Name
        $r | Should beNullOrEmpty
    }
    It 'invoke a command from the module' {
        $r = & "f-$guid"
        $r | Should be 'result of f'
    }
}
Describe 'unimported dynamic modules are not removed using Remove-Module' {
    It 'remove the module' {
        $h.DynamicModule | Remove-Module
    }
    It 'the command from the removed module still works' {
        $r = & "f-$guid"
        $r | Should be 'result of f'
    }
}
Describe 'overwrite the dynamic module with an empty one' {
    It 'overwrite the module' {
        $h.DynamicModule = New-Module -Name "DynamicModule-$guid" -ScriptBlock {}
        $h.DynamicModule.ExportedFunctions |
            Should beNullOrEmpty
    }
    It 'the command from the overwritten module still works' {
        $r = & "f-$guid"
        $r | Should be 'result of f'
    }
}
Describe 'force import the Dynamic Module' {
    It 'force the import' {
        $h.DynamicModule | Import-Module
    }
    It 'the module is retrieved by Get-Module' {
        $r = Get-Module "DynamicModule-$guid"
        $r | Should not beNullOrEmpty
    }
}
Describe 'remove the force-imported Dynamic Module' {
    It 'remove the module' {
        $h.DynamicModule | Remove-Module
    }
    It 'the module is no longer retrieved by Get-Module' {
        $r = Get-Module "DynamicModule-$guid"
        $r | Should beNullOrEmpty
    }
    It 'the command from the removed module still works' {
        $r = & "f-$guid"
        $r | Should be 'result of f'
    }
}

$guid = [guid]::NewGuid().Guid
Describe 'use one dynamic module from another' {
    It 'create inner module' {
        $h.ModuleA = New-Module -Name "ModuleA-$guid" -ScriptBlock (
            [scriptblock]::Create("function A-$guid { 'result of A' }")
        )
    }
    It 'create outer module' {
        $h.ModuleB = New-Module -Name "ModuleB-$guid" -ScriptBlock (
            [scriptblock]::Create("function B-$guid { `"B calls A: `$(A-$guid)`"}")
        )
    }
    It 'command in inner module works' {
        $r = & "A-$guid"
        $r | Should be 'result of A'
    }
    It 'command in outer module calls inner module' {
        $r = & "B-$guid"
        $r | Should be 'B Calls A: result of A'
    }
}
