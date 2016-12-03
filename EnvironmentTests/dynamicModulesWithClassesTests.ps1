$guidFrag = [guid]::NewGuid().Guid.Split('-')[0]

Describe 'Reloading Dynamic Modules Containing Classes' {
    $scriptString = @'
        `$passedArgs = `$args
        class c {
            `$passedIn = `$passedArgs
            `$literal = $literal
        }
        function Get-PassedArgs$guidFrag { `$passedArgs }
        function Get-C$guidFrag { [c]::new() }
'@
    $tests = [ordered]@{
        'create module passing arguments' = @(
            'literal1', 'argument1','literal1','argument1','argument1'
        )
        'overwrite identical module passing different arguments' = @(
            'literal1', 'argument2','literal1','argument2','argument1' # <== how it is
          # 'literal1', 'argument2','literal1','argument2','argument2' # <== how it should be
        )
        'create module with different class definition' = @(
            'literal2', 'argument3','literal2','argument3','argument3'
        )
    }
    foreach ( $key in $tests.Keys )
    {
        $plainLiteral,$argument,$expectedLiteral,$expectedArgument,$expectedProperty = $tests.$key
        $literal = "'$plainLiteral'"
        Context $key {
            It "create module containing literal $literal with argument $argument" {
                $module = New-Module "m-$guidFrag" (
                    [scriptblock]::Create($ExecutionContext.InvokeCommand.ExpandString($scriptString))
                ) -ArgumentList $argument
            }
            It "module argument $expectedArgument is returned from function" {
                $r = & "Get-PassedArgs$guidFrag"
                $r | Should be $expectedArgument
            }
            It "module argument $expectedProperty is returned by class" {
                $r = & "Get-C$guidFrag"
                $r.passedIn | Should be $expectedProperty
            }
            It "literal $literal is available from class" {
                $r = & "Get-C$guidFrag"
                $r.literal | Should be $expectedLiteral
            }
        }
    }
}
