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
$psVintage = if ( $PSVersionTable.PSVersion.Major -lt 3 )
    {
        'Old'
    }
    else
    {
        'Modern'
    }
$h = @{}

$testFile = 'testFile'

Describe 'collect variable scopes' {
    BeforeEach {
        $beforeEach = 'beforeEach'
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
        param ($Scope,$VariableName)
        $h.f.$Scope |
            ? {$_.Name -eq $VariableName} |
            % {$_.Value}
    }
    It 'there are nine scopes' {
        $h.f.Keys.Count | Should be 9
    }
    Context 'variable defined in test file scope' {
        foreach ($scope in @{
                Modern = 'Unmodified','Global',6,4
                Old    = 'Unmodified',4
            }.$psVintage
        )
        {
            It "exists in scope: $scope" {
                $r = Get-VariableValue $scope testFile
                $r | Should be 'testFile'
            }
        }
        foreach ( $scope in @{
                Modern = 5,3,2,1,0
                Old    = 'Global',6,5,3,2,1,0
            }.$psVintage
        )
        {
            It "does not exist in scope: $scope" {
                $r = Get-VariableValue $scope testFile
                $r | Should beNullOrEmpty
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
        param ($Scope,$VariableName)
        $h.g.$Scope |
            ? {$_.Name -eq $VariableName} |
            % {$_.Value}
    }
    It 'there are five scopes' {
        $h.g.Keys.Count | Should be 5
    }
    Context 'variable defined in testFile scope' {
        foreach ($scope in @{
                Modern = 'Unmodified','Global',2
                Old    = @()
            }.$psVintage
        )
        {
            It "exists in scope: $scope" {
                $r = Get-VariableValue $scope testFile
                $r | Should be 'testFile'
            }
        }
        foreach ( $scope in @{
                Modern = 4,3,1,0
                Old    = 'Unmodified','Global',4,3,2,1,0
            }.$psVintage
        )
        {
            It "does not exist in scope: $scope" {
                $r = Get-VariableValue $scope testFile
                $r | Should beNullOrEmpty
            }
        }
    }
    foreach ( $definitionLocation in ('beforeEach','context','it') )
    {
        Context "variable defined in $definitionLocation testFile" {
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
