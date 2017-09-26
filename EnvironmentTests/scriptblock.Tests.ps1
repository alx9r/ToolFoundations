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

Describe 'invoke scriptblock in parent context (https://stackoverflow.com/q/46428736/1404637)' {
    New-Module m {
        function SomeScriptblockInvoker {
            param
            (
                [Parameter(Position = 1)]
                [scriptblock]
                $Scriptblock,

                [Parameter(ValueFromPipeline)]
                $InputObject
            )
            process
            {
                $modifiedLocal = 'variable name collision'
                $local = 'variable name collision'
                $InputObject | ForEach-Object $Scriptblock
            }
        }
    } |
        Import-Module
    $sb = {
        $modifiedLocal = 'modified local value'
        [pscustomobject] @{
            Local = $local
            DollarBar = $_
        }
    }
    foreach ( $commandName in 'ForEach-Object','SomeScriptblockInvoker' )
    {
        Context $commandName {
            $modifiedLocal = 'original local value'
            $local = 'local'
            $r = 'input object' | & $commandName $sb
            It 'Local is accessible' {
                $r.Local | Should be 'local'
            }
            It 'DollarBar is input object' {
                $r.DollarBar | Should be 'input object'
            }
            It 'modifies local variable' {
                $modifiedLocal | Should be 'modified local value'
            }
        }
    }
}
