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
            'literal 1', 'argument 1'
        )
        'overwrite identical module passing different arguments' = @(
          # 'literal 1', 'argument 2' # <== how it should be
            'literal 1', 'argument 1' # <== how it is
        )
        'create module with different class definition' = @(
            'literal 2', 'argument 3'
        )
    }
    foreach ( $key in $tests.Keys )
    {
        $plainLiteral,$argument = $tests.$key
        $literal = "'$plainLiteral'"
        Context $key {
            It 'create module' {
                $module = New-Module "m-$guidFrag" (
                    [scriptblock]::Create($ExecutionContext.InvokeCommand.ExpandString($scriptString))
                ) -ArgumentList $argument
            }
            It 'correct module arguments are available from function' {
                $r = & "Get-PassedArgs$guidFrag"
                $r | Should be $argument
            }
            It 'correct module arguments are available from class' {
                $r = & "Get-C$guidFrag"
                $r.passedIn | Should be $argument
            }
            It 'correct literal is available from class' {
                $r = & "Get-C$guidFrag"
                $r.literal | Should be $plainLiteral
            }
        }
    }
}
