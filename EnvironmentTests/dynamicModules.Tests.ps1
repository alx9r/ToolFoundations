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
    It 'invoke a command from the module' {
        $r = & "f-$guid"
        $r | Should be 'result of f'
    }
}
Describe 'dynamic modules are not removed using Remove-Module' {
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