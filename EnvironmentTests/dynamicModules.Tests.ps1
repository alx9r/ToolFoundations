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
Describe 'import one dynamic module from another' {
    It 'create moduleA' {
        $h.ModuleA = New-Module -Name "ModuleA-$guid" -ScriptBlock (
            [scriptblock]::Create("function A-$guid { 'result of A' }")
        )
    }
    It 'force import ModuleA' {
        $h.ModuleA | Import-Module -Force -WarningAction SilentlyContinue
    }
    It 'create module B' {
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
