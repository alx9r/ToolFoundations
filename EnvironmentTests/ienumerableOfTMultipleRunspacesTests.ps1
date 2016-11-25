$modulePath = "$PSScriptRoot\ienumerableOfT.psm1"
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

Describe 'module containing IEnumerable<T> across runspaces' {
    It 'save original location' {
        $h.OriginalLocation = Get-Location
    }
    It "set location to $PSScriptRoot" {
        $PSScriptRoot | Set-Location
    }
    It 'getting enumerator in the first runspace succeeds' {
        $runspace = [runspacefactory]::CreateRunspace()
        $ps = [powershell]::Create()
        $ps.Runspace =$runspace
        $runspace.Open()
        $ps.AddScript($scriptblock)
        $ps.AddParameter('ModulePath',$modulePath)

        $r = $ps.Invoke()
        $r | Should be 'no exception'
    }
    if ( $PSVersionTable.PSVersion -ge '5.1' )
    {
        It 'in PowerShell 5.1 and later getting enumerator in the second runspace succeeds' {
            $runspace = [runspacefactory]::CreateRunspace()
            $ps = [powershell]::Create()
            $ps.Runspace =$runspace
            $runspace.Open()
            $ps.AddScript($scriptblock)
            $ps.AddParameter('ModulePath',$modulePath)

            $r = $ps.Invoke()
            $r | Should match 'no exception'
        }
    }
    else
    {
        It 'before PowerShell 5.1 getting enumerator in the second runspace throws' {
            $runspace = [runspacefactory]::CreateRunspace()
            $ps = [powershell]::Create()
            $ps.Runspace =$runspace
            $runspace.Open()
            $ps.AddScript($scriptblock)
            $ps.AddParameter('ModulePath',$modulePath)

            $r = $ps.Invoke()
            $r | Should match "The term 'FunctionName' is not recognized"
        }
    }
    It 'restore original location' {
        $h.OriginalLocation | Set-Location
    }
}
