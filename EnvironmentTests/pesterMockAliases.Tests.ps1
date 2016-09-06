<#
This file tests whether mocking of a function works
when its alias is used instead of the function name.
#>
Describe 'mocking and aliases' {
    It 'cls is an alias' {
        $r = Get-Command cls
        $r.CommandType | Should be 'Alias'
    }
    It 'Clear-Host is a command' {
        $r = Get-Command Clear-Host
        $r.CommandType | Should be 'Function'
    }
    Context 'mocking original function works' {
        Mock Clear-Host { 'mock' }
        function Invoke-ClearHost { Clear-Host }
        function Invoke-Cls { cls }
        It 'original function gets mocked' {
            $r = Invoke-ClearHost
            $r | Should be 'mock'
        }
        It 'alias in function invokes mock' {
            $r = Invoke-Cls
            $r | Should be 'mock'
        }
    }
    Context 'mocking alias works' {
        Mock cls {'mock'}
        function Invoke-ClearHost { Clear-Host }
        function Invoke-Cls { cls }
        It 'original function gets mocked' {
            $r = Invoke-ClearHost
            $r | Should be 'mock'
        }
        It 'alias in function invokes mock' {
            $r = Invoke-Cls
            $r | Should be 'mock'
        }
    }
}
