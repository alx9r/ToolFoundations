Describe "Invoke-Ternary" {
    BeforeEach {
        Remove-Module ToolFoundations -ea SilentlyContinue
        Import-Module ToolFoundations
    }

    It "correctly interprets boolean true" {
        $true | ?: 'true' 'false' | Should Be 'true'
    }

    It "correctly interprets boolean true" {
        $false | ?: 'true' 'false' | Should Be 'false'
    }

    It "correctly interprets null" {
        $null | ?: 'true' 'false' | Should Be 'false'
    }

    It "correctly interprets empty list" {
        @() | ?: 'true' 'false' | Should Be 'false'
    }

    It "correctly interprets empty hash table" {
        @{} | ?: 'true' 'false' | Should Be 'true'
    }

    It "correctly interprets list whose last value is false" {
        @($true,$false) | ?: 'true' 'false' | Should Be 'false'
    }

    It "correctly interprets list whose last value is true" {
        @($false,$true) | ?: 'true' 'false' | Should Be 'true'
    }

    Context "delayed execution of scriptblock" {

        It "correctly delays execution of true scriptblock" {
            $Global:9b57b26a = 1
            $Global:9b57b26a | ?: {
                $Global:9b57b26a
                $Global:9b57b26a = 0
            } 'false' | Should be 1
            $Global:9b57b26a | Should be 0
        }

        It "correctly delays execution of false scriptblock" {
            $Global:9b57b26a = 0
            $Global:9b57b26a | ?: 'false' {
                $Global:9b57b26a
                $Global:9b57b26a = 1
            } | Should be 0
            $Global:9b57b26a | Should be 1
        }

        AfterEach {
            Remove-Variable $Global:9b57b26a -ea SilentlyContinue
        }
    }

    Context "variable expansion" {
        BeforeEach {
            $MyString = 'The $animal says $sound.'
            $animal = 'fox'
            $sound = 'simper'
            $FoxSimper = 'The fox says simper.'
        }

        It "correctly expands variables in true parameter" {
            $true | ?: "The $animal says $sound." 'false' | Should be $FoxSimper
        }

        It "correctly expands variables in scriptblock true parameter" {
            $true | ?: {"The $animal says $sound."} 'false' | Should be $FoxSimper
        }

        It "correctly expands variables in false parameter" {
            $false | ?: 'true' "The $animal says $sound." | Should be $FoxSimper
        }

        It "correctly expands variables in scriptblock false parameter" {
            $false | ?: 'true' {"The $animal says $sound."} | Should be $FoxSimper
        }
    }

    Context 'no alternate' {
        It 'emits nothing on false when no alternate is provided.' {
            $false,0,$null | ?: 'true' | Should BeNullOrEmpty
        }
    }
}


Describe "Invoke-IfScriptblock" {
    BeforeEach {
        Remove-Module ToolFoundations -ea SilentlyContinue
        Import-Module ToolFoundations
    }
    It "outputs a non-scriptblock object" {
        Invoke-IfScriptBlock "string" | Should be 'string'
    }
    It "evaluates a scriptblock" {
        Invoke-IfScriptBlock { 2*2 } | Should be 4
    }
}
