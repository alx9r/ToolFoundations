Import-Module ToolFoundations -Force

Describe Get-BoundParams {
    BeforeEach {
        Remove-Module ToolFoundations -ea SilentlyContinue
        Import-Module ToolFoundations
    }
    BeforeEach {
        Function Test-GetBoundParams
        {
            [CmdletBinding()]
            param($p1,$p2,$test)
            process
            {
                switch ($test)
                {
                    1 { Get-BoundParams     }
                    2 { & (Get-BoundParams) }
                    3 { & (gbpm)            }
                    4 { & (gbpm -IncludeCommonParameters ) }
                }
            }
        }
    }

    AfterEach {
        Remove-Item function:Test-GetBoundParams -force
    }

    It "outputs [scriptblock]" {
        (Test-GetBoundParams -test 1) -is [scriptblock] |
            Should be $true
    }
    It "produces an object with the bound parameters as properties (test 2)." {
        $o = Test-GetBoundParams -test 2 -p1 'foo' -p2 123456

        $o.p1 | Should be 'foo'
        $o.p2 | Should be 123456
    }
    It "produces an object with the bound parameters as properties (test 3)." {
        $o = Test-GetBoundParams -test 3 -p1 'foo' -p2 123456

        $o.p1 | Should be 'foo'
        $o.p2 | Should be 123456
    }
    It "omits a common parameter. (test 3)" {
        $o = Test-GetBoundParams -test 3 -p1 'foo' -p2 123456 -Verbose

        $o.p1 | Should be 'foo'
        $o.p2 | Should be 123456
        $o -Contains 'Verbose' | Should be $false
    }
    It "includes a common parameter. (test 4)" {
        $o = Test-GetBoundParams -test 4 -p1 'foo' -p2 123456 -Verbose

        $o.p1 | Should be 'foo'
        $o.p2 | Should be 123456
        $o.Keys -Contains 'Verbose' | Should be $true
    }
}
InModuleScope ToolFoundations {
    Describe Get-CommonParams {
        BeforeAll {
            Function Test-CommonParams1
            {
                [CmdletBinding()]
                param($params=@{})
                process
                {
                    $oSplat = &(gcp @params)
                    Test-CommonParams2 @oSplat
                }
            }
            Function Test-CommonParams2
            {
                [CmdletBinding()]
                param()
                process{&(gbpm -IncludeCommonParameters )}
            }
        }
        AfterAll {
            Remove-Item function:Test-CommonParams1 -Force
            Remove-Item function:Test-CommonParams2 -Force
        }
        It 'outputs [scriptblock].' {
            $r = gcp

            $r -is [scriptblock] |
                Should be $true
        }
        It 'defaults to empty hashtable.' {
            $result = (&(gcp))

            $result -is [hashtable] |
                Should be $true
            $result.Keys |
                Should beNullOrEmpty
        }
        It 'cascades -Verbose. (True)' {
            $bp = Test-CommonParams1 -Verbose

            $bp.Keys -Contains 'Verbose' |
                Should be $true
            $bp.Verbose |
                Should be $true
            $bp.Keys.Count |
                Should be 1
        }
        It 'cascades -Verbose. (False)' {
            $bp = Test-CommonParams1 -Verbose:$false

            $bp.Keys -Contains 'Verbose' |
                Should be $true
            $bp.Verbose |
                Should be $false
            $bp.Keys.Count |
                Should be 1
        }
        Context 'bad ParamList item' {
            Mock Write-Error -Verifiable
            It 'returns hashtable with remaining items.' {
                $bp = Test-CommonParams1 -Verbose -params @{ParamList = 'Verbose','Invalid'}

                $bp.Keys -contains 'Verbose' |
                    Should be $true
                $bp.Keys.Count |
                    Should be 1
            }
            It 'reports correct error.' {
                Assert-MockCalled Write-Error -Exactly -Times 1
                Assert-MockCalled Write-Error -Exactly -Times 1 {
                    $Message -eq '"Invalid" is not a valid Common Parameter.'
                }
            }
        }
    }
}
Describe Publish-Failure {
    Context 'specified exception' {
        function Fail
        {
            &(Publish-Failure 'My Error Message','param1' -ExceptionType System.ArgumentException -FailAction Throw)
        }
        It 'throws correct exception.' {
            try
            {
                Fail
            }
            catch [System.ArgumentException]
            {
                $threw = $true

                $_.CategoryInfo.Reason | Should be 'ArgumentException'
                $_ | Should Match 'My Error Message'
                $_ | Should Match 'Parameter name: param1'

                if ($PSVersionTable.PSVersion.Major -ge 4)
                {
                    $_.ScriptStackTrace | Should Match 'at Fail, '
                    $_.ScriptStackTrace | Should not match 'cmdlet.ps1'
                }
            }
            $threw | Should be $true
        }
    }
    Context 'unspecified exception type' {
        function Fail
        {
            &(Publish-Failure 'My Error Message','param1' -FailAction Throw)
        }
        It 'throws a generic exception.' {
            try
            {
                Fail
            }
            catch
            {
                $threw = $true

                $_.CategoryInfo.Reason | Should be 'Exception'
                $_ | Should Match 'My Error Message'
            }
            $threw | Should be $true
        }
    }
    Context 'Verbose' {
        function Fail
        {
            &(Publish-Failure 'My Error Message','param1' -ExceptionType System.ArgumentException -FailAction Verbose)
        }
        Mock Write-Verbose -Verifiable
        It 'reports correct error message.' {
            Fail

            Assert-MockCalled Write-Verbose -Times 1 {
                $Message -eq 'My Error Message'
            }
        }
    }
    Context 'Error' {
        function Fail
        {
            &(Publish-Failure 'My Error Message','param1' -ExceptionType System.ArgumentException -FailAction Error)
        }
        Mock Write-Error -Verifiable
        It 'reports correct error message.' {
            Fail

            Assert-MockCalled Write-Error -Times 1 {
                $Message -eq 'My Error Message'
            }
        }
    }
}
Describe ConvertTo-ParamObject {
    It 'outputs a psobject with correct properties (1)' {
        $r = @{a=1} | ConvertTo-ParamObject
        $r -is [psobject] | Should be true

        $r |
            Get-Member |
            ? {
                $_.MemberType -like '*property*' -and
                $_.Name -eq 'a'
            } |
            Measure | % {$_.Count} |
            Should be 1
    }
    It 'outputs a psobject with correct properties (2)' {
        $h = @{
            string  = 'this is a string'
            integer = 12345678
            boolean = $true
            hashtable = @{a=1}
            array = 1,2,3
        }
        $r = $h | ConvertTo-ParamObject
        $r.string | Should be 'this is a string'
        $r.integer | Should be 12345678
        $r.boolean | Should be $true
        $r.hashtable.a | Should be 1
        $r.array[1] | Should be 2

        $r |
            Get-Member |
            ? {$_.MemberType -like '*property*'} |
            % {$_.Name} |
            ? {$h.keys -contains $_} |
            measure | % {$_.Count} |
            Should be 5
    }
    It 'accepts an object.' {
        $h = @{
            string  = 'this is a string'
            integer = 12345678
            boolean = $true
            hashtable = @{a=1}
            array = 1,2,3
        }
        $o = New-Object psobject -Property $h
        $r = $o | ConvertTo-ParamObject
        $r.string | Should be 'this is a string'
        $r.integer | Should be 12345678
        $r.boolean | Should be $true
        $r.hashtable.a | Should be 1
        $r.array[1] | Should be 2
    }
    It 'does not recurse.' {
        $h = @{
            h = @{
                a=1
            }
        }
        $r = $h | ConvertTo-ParamObject
        $r.h -is [hashtable] | Should be $true
    }
    It 'creates correct object from PSBoundParameters.'{
        $dict = New-Object 'System.Collections.Generic.Dictionary`2[System.String,System.Object]'
        ('string',    'this is a string' ),
        ('integer',   12345678 ),
        ('boolean',   $true ),
        ('hashtable', @{a=1} ),
        ('array',     @(1,2,3) ) |
            % {
                $dict.Add($_[0],$_[1])
            }
        $r = $dict | ConvertTo-ParamObject
        $r.string | Should be 'this is a string'
        $r.integer | Should be 12345678
        $r.boolean | Should be $true
        $r.hashtable.a | Should be 1
        $r.array[1] | Should be 2
    }
}
if ($PSVersionTable.PSVersion.Major -ge 4)
{
InModuleScope ToolFoundations {
    Describe Get-Parameters {
        Context 'bad ParameterSetName' {
            function Test-BadParameterSetName
            {
                [CmdletBinding()]
                param
                (
                    [Parameter(ParameterSetName='a')]
                    $a
                )
            }
            It 'throws correct exception.' {
                try
                {
                    Get-Parameters Test-BadParameterSetName BadParameterSetName -Mode Required
                }
                catch [System.ArgumentException]
                {
                    $threw = $true
                    $_.Exception.Message | Should match 'Cmdlet Test-BadParameterSetName does not have ParameterSetName BadParameterSetName.'
                    $_.Exception.ParamName | Should be 'ParameterSetName'
                }
                $threw | Should be $true
            }
        }
        Context 'no parameters' {
            function Test-NoParameters
            {
                [CmdletBinding()]
                param()
            }
            It 'returns nothing.' {
                $r = Get-Parameters Test-NoParameters
                $r | Should beNullOrEmpty
            }
        }
        Context 'invalid CmdletName' {
            It 'throws correct exception.' {
                try
                {
                    Get-Parameters Test-BadCmdletName
                }
                catch [System.Management.Automation.CommandNotFoundException]
                {
                    $threw = $true
                    $_.Exception.Message | Should match "The term 'Test-BadCmdletName' is not recognized"
                    $_.Exception.CommandName | Should be 'Test-BadCmdletName'
                }

                $threw | Should be $true
            }
        }
        Context 'single parameter set' {
            function Test-OneParameterSet
            {
                [CmdletBinding()]
                param
                (
                    [Parameter(Mandatory = $true)]
                    $a,

                    $b
                )
            }

            It 'reports correct parameters (required)' {
                $r = Get-Parameters Test-OneParameterSet -Mode Required
                $r[0] | Should be 'a'
                $r.Count | Should be 1
            }
            It 'reports correct parameters (All)' {
                $r = Get-Parameters Test-OneParameterSet -Mode All
                $r[0] | Should be 'a'
                $r[1] | Should be 'b'
                $r.Count | Should be 2
            }
        }
        Context 'default parameter set.' {
            function Test-DefaultParameterSet
            {
                [CmdletBinding(DefaultParameterSetName = 'b')]
                param
                (
                    [Parameter(ParameterSetName = 'a')]
                    $a,

                    [Parameter(Mandatory = $true, ParameterSetName = 'b')]
                    $b,

                    [Parameter(Mandatory = $true)]
                    $c
                )
            }
            It 'reports correct parameters (required)' {
                $r = Get-Parameters Test-DefaultParameterSet -Mode Required
                $r[0] | Should be 'b'
                $r[1] | Should be 'c'
            }
            It 'reports correct parameters (all)' {
                $r = Get-Parameters Test-DefaultParameterSet -Mode All
                $r[0] | Should be 'b'
                $r[1] | Should be 'c'
            }
        }
        Context 'selected parameter set.' {
            function Test-DefaultParameterSet
            {
                [CmdletBinding(DefaultParameterSetName = 'b')]
                param
                (
                    [Parameter(Mandatory = $true,ParameterSetName = 'a')]
                    $a,

                    [Parameter(ParameterSetName = 'a')]
                    $aoptional,

                    [Parameter(ParameterSetName = 'b')]
                    $b,

                    [Parameter(Mandatory = $true)]
                    $c
                )
            }
            It 'reports correct parameters (required)' {
                $r = Get-Parameters Test-DefaultParameterSet a -Mode Required
                $r[0] | Should be 'a'
                $r[1] | Should be 'c'
            }
            It 'reports correct parameters (all)' {
                $r = Get-Parameters Test-DefaultParameterSet a -Mode All
                $r[0] | Should be 'a'
                $r[1] | Should be 'aoptional'
                $r[2] | Should be 'c'
            }
        }
        Context 'no parameter set provided' {
            function Test-NoDefaultParameterSet
            {
                [CmdletBinding()]
                param
                (
                    [Parameter(Mandatory = $true,ParameterSetName = 'a')]
                    $a,

                    [Parameter(Mandatory = $true, ParameterSetName = 'b')]
                    $b,

                    $c
                )
            }
            It 'throws correct exception.' {
                try
                {
                    Get-Parameters Test-NoDefaultParameterSet -Mode Required
                }
                catch [System.ArgumentException]
                {
                    $threw = $true
                    $_.Exception.Message | Should match 'Cmdlet Test-NoDefaultParameterSet has more than one parameterset and no default. You must provide ParameterSetName.'
                    $_.Exception.ParamName | Should be 'ParameterSetName'
                }
            }
        }
    }
    Describe Test-ValidParams {
        Context 'success.' {
            Mock Get-Parameters -Verifiable { 'a','b' }
            It 'returns true.' {
                $splat = @{
                    CmdletName  = 'Do-Something'
                    SplatParams = @{a=1;b=2}
                }
                $r = Test-ValidParams @splat
                $r | Should be $true

                Assert-MockCalled Get-Parameters -Times 1 {
                    $CmdletName -eq 'Do-Something'
                }
            }
        }
        Context 'missing parameter.' {
            Mock Get-Parameters -Verifiable { 'a','b' }
            It 'throws correct exception.' {
                $splat = @{
                    CmdletName  = 'Do-Something'
                    SplatParams = @{b=2}
                }
                try
                {
                    Test-ValidParams @splat -FailAction Throw
                }
                catch
                {
                    $threw = $true
                    $_.Exception.Message | Should match 'Required parameter a not in SplatParams for Cmdlet Do-Something'
                    $_.Exception.ParamName | Should be 'a'
                }
                $threw | Should be $true
            }
        }
        Context 'extra parameter.' {
            Mock Get-Parameters -Verifiable { 'a','b' }
            It 'throw correct exceptions.' {
                $splat = @{
                    CmdletName  = 'Do-Something'
                    SplatParams = @{a=1;b=2;c=3}
                }
                try
                {
                    Test-ValidParams @splat -FailAction Throw
                }
                catch
                {
                    $threw = $true
                    $_.Exception.Message | Should match 'SplatParam c provided but not a parameter of Cmdlet Do-Something'
                    $_.Exception.ParamName | Should be 'c'
                }
                $threw | Should be $true
            }
        }
    }
}
InModuleScope ToolFoundations {
    Describe Invoke-CommandSafely {
        function Test
        {
            [CmdletBinding()]
            param
            (
                [Parameter(Mandatory=$true)]
                $x
            )
            process
            {
                return $x
            }
        }

        It 'throws on missing param.' {
            $splat = @{}
            { Invoke-CommandSafely Test $splat } | Should throw
        }
        Context 'does not invoke' {
            Mock Test -Verifiable
            It 'does not invoke on missing param.' {
                $splat = @{}
                try
                {
                    Invoke-CommandSafely Test $splat
                }
                catch [System.ArgumentException]
                {
                    $throws = $true
                }

                $throws | Should be $true

                Assert-MockCalled Test -Times 0
            }
        }
        It 'invokes on good params.' {
            $splat = @{
                x = 100
            }
            $r = Invoke-CommandSafely Test $splat
            $r | Should be 100
        }
    }
}
}
