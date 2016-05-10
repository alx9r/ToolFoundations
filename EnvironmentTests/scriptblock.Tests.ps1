Describe 'pass values to scriptblock' {
    $scriptBlockWithoutModule = {
        @{
            DollarBar = $_
            Arg = $args[0]
        }
    }
    $module = New-Module {}
    $scriptBlockWithModule = $module.NewBoundScriptBlock($scriptBlockWithoutModule)
    $scriptBlockNotBoundToModule = [scriptblock]::Create($scriptBlockWithoutModule)

    Context '$_ empty, $args populated' {
        It 'ScriptBlock without module' {
            $r = 'pipedValue' | & $scriptBlockWithoutModule 'a'
            $r.DollarBar | Should beNullOrEmpty
            $r.Arg | Should be 'a'
        }
        It 'ScriptBlock with module' {
            $r = 'pipedValue' | & $scriptBlockWithModule 'a'
            $r.DollarBar | Should beNullOrEmpty
            $r.Arg | Should be 'a'
        }
        It 'ScriptBlock not bound to module' {
            $r = 'pipedValue' | & $scriptBlockNotBoundToModule 'a'
            $r.DollarBar | Should beNullOrEmpty
            $r.Arg | Should be 'a'
        }
        It 'ScriptBlock with module' {
            $r = 'pipedValue' | % { & $scriptBlockWithModule 'a' }
            $r.DollarBar | Should beNullOrEmpty
            $r.Arg | Should be 'a'
        }
    }
    Context '$_ populated, $args populated' {
        It 'ScriptBlock without module' {
            $r = 'pipedValue' | % { & $scriptBlockWithoutModule 'a' }
            $r.DollarBar | Should be 'pipedValue'
            $r.Arg | Should be 'a'
        }
        It 'ScriptBlock not bound to module' {
            $r = 'pipedValue' | % { & $scriptBlockNotBoundToModule 'a' }
            $r.DollarBar | Should be 'pipedValue'
            $r.Arg | Should be 'a'
        }
    }
}
