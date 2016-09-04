function f {
    $r = @{
        Global = Get-Variable -Scope Global
        Unmodified = Get-Variable
    }
    try
    {
        $i=0
        while ($true)
        {
            $r.$i = Get-Variable -Scope $i
            $i++
        }
    }
    catch [System.ArgumentOutOfRangeException]
    {
    }
    return $r
}
$module = New-Module {
    function g {
        $r = @{
            Global = Get-Variable -Scope Global
            Unmodified = Get-Variable
        }
        try
        {
            $i=0
            while ($true)
            {
                $r.$i = Get-Variable -Scope $i
                $i++
            }
        }
        catch [System.ArgumentOutOfRangeException]
        {
        }
        return $r
    }
}

$h = @{}
$h.DirectlyInvokedScript = -not [bool]$MyInvocation.Line
$h.PesterInvokedScript = $MyInvocation.Line -match '&\ \$Path\ @Parameters\ @Arguments'
$h.ScriptInvokationMethod = if     ( $h.DirectlyInvokedScript ) { 'Direct' }
                      elseif ( $h.PesterInvokedScript )   { 'Pester' }

$testFile = 'testFile'

Describe 'collect variable scopes' {
    BeforeEach {
        $beforeEach = 'beforeEach'
    }
    BeforeAll {
        $beforeAll = 'beforeAll'
    }
    Context 'context block' {
        $context = 'context'
        It 'it block' {
            $it = 'it'
            $h.f = f
            $h.g = g
        }
    }
}
Describe 'evaluate variable scopes: FUT not in module' {
    function Get-VariableValue {
        param ($_Scope,$VariableName)
        $h.f.$_Scope |
            ? {$_.Name -eq $VariableName} |
            % {$_.Value}
    }
    $numScopes = @{
        Direct = 7
        Pester = 9
    }.($h.ScriptInvokationMethod)
    It "there are $numScopes scopes" {
        $h.f.Keys.Count | Should be $numScopes
    }
    foreach ( $definitionLocation in 'testFile','BeforeAll' )
    {
        Context "variable defined in $definitionLocation scope; ScriptInvokationMethod is $($h.ScriptInvokationMethod)" {
            foreach ($scope in @{
                    Pester = 'Unmodified',4
                    Direct = 'Unmodified',4,'Global'
                }.($h.ScriptInvokationMethod)
            )
            {
                It "exists in scope: $scope" {
                    $r = Get-VariableValue $scope $definitionLocation
                    $r | Should be $definitionLocation
                }
            }
            foreach ( $scope in @{
                    Pester = 'Global',6,5,3,2,1,0
                    Direct = 6,5,3,2,1,0
                }.($h.ScriptInvokationMethod)
            )
            {
                It "does not exist in scope: $scope; ScriptInvokationMethod is $($h.ScriptInvokationMethod)" {
                    $r = Get-VariableValue $scope $definitionLocation
                    $r | Should beNullOrEmpty
                }
            }
        }
    }
    foreach ( $definitionLocation in ('beforeEach','context') )
    {
        Context "variable defined in $definitionLocation block" {
            foreach ( $scope in ('Unmodified',2) )
            {
                It "exists in scope: $scope" {
                    $r = Get-VariableValue $scope $definitionLocation
                    $r | Should be $definitionLocation
                }
            }
            foreach ( $scope in ('Global',6,5,4,3,1,0) )
            {
                It "does not exist in scope: $scope" {
                    $r = Get-VariableValue $scope $definitionLocation
                    $r | Should beNullOrEmpty
                }
            }
        }
    }
    Context 'variable defined in it block' {
        foreach ($scope in ('Unmodified',1) )
        {
            It "exists in scope: $scope" {
                $r = Get-VariableValue $scope it
                $r | Should be 'it'
            }
        }
        foreach ( $scope in ('Global',6,5,4,3,2,0) )
        {
            It "does not exist in scope: $scope" {
                $r = Get-VariableValue $scope it
                $r | Should beNullOrEmpty
            }
        }
    }
}
Describe 'evaluate variable scopes: FUT in Module' {
    function Get-VariableValue {
        param ($_Scope,$VariableName)
        $h.g.$_Scope |
            ? {$_.Name -eq $VariableName} |
            % {$_.Value}
    }
    It 'there are five scopes' {
        $h.g.Keys.Count | Should be 5
    }
    foreach ( $definitionLocation in ('testFile','beforeAll') )
    {
        Context "variable defined in $definitionLocation; ScriptInvokationMethod is $($h.ScriptInvokationMethod)" {
            foreach ( $scope in @{
                    Pester = @()
                    Direct = 'Global','Unmodified',2
                }.($h.ScriptInvokationMethod)
            )
            {
                It "exists in scope: $scope" {
                    $r = Get-VariableValue $scope $definitionLocation
                    $r | Should be $definitionLocation
                }
            }
            foreach ( $scope in @{
                    Pester = 'Global','Unmodified',2,1,0
                    Direct = 1,0
                }.($h.ScriptInvokationMethod)
            )
            {
                It "does not exist in scope: $scope" {
                    $r = Get-VariableValue $scope $definitionLocation
                    $r | Should beNullOrEmpty
                }
            }
        }
    }
    foreach ( $definitionLocation in ('beforeEach','context','it') )
    {
        Context "variable defined in $definitionLocation scope; ScriptInvokationMethod is $($h.ScriptInvokationMethod)" {
            foreach ( $scope in ($h.g.Keys) )
            {
                It "does not exist in scope: $scope" {
                    $r = Get-VariableValue $scope $definitionLocation
                    $r | Should beNullOrEmpty
                }
            }
        }
    }
}

Remove-Variable 'testFile','beforeEach','beforeAll','context','it' -ea SilentlyContinue
