$scriptblock = {
    param($ModulePath)

    $PSModuleAutoLoadingPreference = $Null
    Import-Module $ModulePath

    $someEnumerable = New-Enumerable
    try
    {
        $someEnumerable.GetEnumerator()
        'no exception'
    }
    catch
    {
        @"
$_
$($_.ScriptStackTrace)
"@
    }
}

$h = @{}

Describe 'module containing IEnumerable across runspaces' {
    $i = 0
    if ( $PSVersionTable.PSVersion -ge '5.1' )
    {
        $label = 'PowerShell 5.1 and later'
        $tests = @(
            #  type, result
            @('ienumerableOfT','^no exception$'),
            @('ienumerableOfT','^no exception$'),
            @('ienumerable','^no exception$'),
            @('ienumerable','^no exception$')
        )
    }
    else
    {
        $label = 'prior to PowerShell 5.1'
        $tests = @(
            #  type, result
            @('ienumerableOfT','^no exception$'),
            @('ienumerableOfT',"The term 'FunctionName' is not recognized"),
            @('ienumerable','^no exception$'),
            @('ienumerable',"The term 'FunctionName' is not recognized")
        )
    }
    Context $label {
        foreach ( $values in $tests )
        {
            $type,$result = $values
            $modulePath = "$PSScriptRoot\$type.psm1"
            $i ++
            It "Runspace $i - getting enumerator from $type results in `"$result`"" {
                $runspace = [runspacefactory]::CreateRunspace()
                $ps = [powershell]::Create()
                $ps.Runspace =$runspace
                $runspace.Open()
                $ps.AddScript($scriptblock)
                $ps.AddParameter('ModulePath',$modulePath)

                $r = $ps.Invoke()
                $r | Should match $result
            }
        }
    }
}
