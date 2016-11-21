Describe '$MyInvocation.MyCommand.Module*' {
    It 'create module' {
        New-Module 'SomeModuleName' {
            function f {
                $MyInvocation
            }
        }
    }
    It '.ModuleName contains module name' {
        $r = f
        $r.MyCommand.ModuleName | Should beOfType ([string])
        $r.MyCommand.ModuleName | Should be 'SomeModuleName'
    }
    It '.Module contains module info' {
        $r = f
        $r.MyCommand.Module | Should beOfType ([psmoduleinfo])
        $r.MyCommand.Module.Name | Should be 'SomeModuleName'
    }
    It 'cleanup' {
        Remove-Item function:\f
    }
}
