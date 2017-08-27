Import-Module ToolFoundations -Force

InModuleScope ToolFoundations {
    Describe 'avoid prompt on missing mandatory parameter (https://stackoverflow.com/questions/33600279)' {
        Context ': reproduce the problem (uncomment the lines to cause blocking)' {
            function f {
                [CmdletBinding()]
                param
                (
                    [Parameter(Mandatory = $true,
                               ValueFromPipeLineByPropertyName=$true)]
                    [ValidateNotNullOrEmpty()]
                    [string]$a
                )
                process{}
            }
            It 'omitting mandatory parameter prompts user and blocks execution.' {
                # uncomment the following line to reproduce the problem.
                # f
            }
        }
        Context ' : scenarios that don''t cause the problem' {
            function f {
                [CmdletBinding()]
                param
                (
                    [Parameter(Mandatory = $true,
                               ValueFromPipeLineByPropertyName=$true)]
                    [string]$a
                )
                process{}
            }
            It 'passing $null to mandatory parameter does not prompt user or block execution.' {
                try
                {
                    f -a $emptyVariable
                }
                catch
                {
                    $threw = $true
                    $_.Exception -is [System.Management.Automation.ParameterBindingException] | Should be $true
                }
                $threw | Should be $true
            }
        }
        Context ": Shay Levy's workaround from https://stackoverflow.com/questions/9506056" {
            function f {
                [CmdletBinding()]
                param
                (
                    [Parameter(ValueFromPipeLineByPropertyName=$true)]
                    [ValidateNotNullOrEmpty()]
                    [string]$a=$(throw 'a is mandatory, please provide a value.')
                )
                process{}
            }
            It 'throws on missing parameter.' {
                try
                {
                    f
                }
                catch
                {
                    $threw = $true
                    $_.Exception.Message | Should match 'a is mandatory, please provide a value.'
                }
                $threw | Should be $true
            }
            It 'throws even when parameter is provided from pipeline (unfortunately)' {
                # this demonstrates why this workaround isn't so great

                $o = New-Object psobject -Property @{a=1}
                $o.a | Should be 1
                try
                {
                    $o | f
                }
                catch
                {
                    $threw = $true
                    $_.Exception.Message | Should match 'a is mandatory, please provide a value.'
                }
                $threw | Should be $true
            }
        }
        if ($PSVersionTable.PSVersion.Major -ge 3)
        {
        Context ': Proactive conversion to object parameter. (PowerShell 3 up)' {
            function f {
                [CmdletBinding()]
                param
                (
                    [Parameter(Mandatory = $true,
                               ValueFromPipeLineByPropertyName=$true)]
                    [ValidateNotNullOrEmpty()]
                    [string]$a,

                    [Parameter(Mandatory = $true ,
                               ValueFromPipeLineByPropertyName=$true)]
                    [ValidateNotNullOrEmpty()]
                    [string]$b,

                    [Parameter(ValueFromPipeLineByPropertyName=$true)]
                    [ValidateNotNullOrEmpty()]
                    [string]$c
                )
                process{}
            }
            BeforeAll {
                $h = @{}
                $h.originalErrorActionPreference = $ErrorActionPreference
                $ErrorActionPreference = 'Stop'
            }
            AfterAll {
                $ErrorActionPreference = $h.originalErrorActionPreference
            }
            It 'ErrorActionPreference is Stop' {
                $ErrorActionPreference | Should be 'Stop'
            }
            It 'throws on missing mandatory parameter.' {
                $o = New-Object psobject -Property @{a=1}
                $o.a | Should be 1
                try
                {
                    $o | f
                }
                catch [System.Management.Automation.ParameterBindingException]
                {
                    $threw = $true
                    $_.Exception.Message | Should match 'The input object cannot be bound because it did not contain the information required to bind all mandatory parameters:  b'
                    $_.Exception.ErrorId | Should be 'InputObjectMissingMandatory'
                }
                $threw | Should be $true
            }
            It 'throws on missing mandatory parameter. (terse)' {
                $pparams = @{
                    a = 1
                }
                try
                {
                    $pparams | >> | f
                }
                catch [System.Management.Automation.ParameterBindingException]
                {
                    $threw = $true
                    $_.Exception.Message | Should match 'The input object cannot be bound because it did not contain the information required to bind all mandatory parameters:  b'
                    $_.Exception.ErrorId | Should be 'InputObjectMissingMandatory'
                }
                $threw | Should be $true
            }
            It 'throws when using both pipeline and named parameter (mandatory param piped)' {
                $pparams = @{
                    a = 1
                }
                    $splat = @{
                    c = 1
                }
                try
                {
                    $pparams | >> | f @splat
                }
                catch [System.Management.Automation.ParameterBindingException]
                {
                    $threw = $true
                    $_.Exception.Message | Should match 'The input object cannot be bound because it did not contain the information required to bind all mandatory parameters:  b'
                    $_.Exception.ErrorId | Should be 'InputObjectMissingMandatory'
                }
                $threw | Should be $true
            }
            It 'throws when using both pipeline and named parameter (mandatory param splatted)' {
                $pparams = @{
                    c = 1
                }
                    $splat = @{
                    a = 1
                }
                try
                {
                    $pparams | >> | f @splat
                }
                catch [System.Management.Automation.ParameterBindingException]
                {
                    $threw = $true
                    $_.Exception.Message | Should match 'The input object cannot be bound because it did not contain the information required to bind all mandatory parameters:  b'
                    $_.Exception.ErrorId | Should be 'InputObjectMissingMandatory'
                }
                $threw | Should be $true
            }
        }
        }
        if ($PSVersionTable.PSVersion.Major -eq 2)
        {
        Context ': Proactive conversion to object parameter. (PowerShell 2)' {
            function f {
                [CmdletBinding()]
                param
                (
                    [Parameter(Mandatory = $true,
                               ValueFromPipeLineByPropertyName=$true)]
                    [ValidateNotNullOrEmpty()]
                    [string]$a,

                    [Parameter(Mandatory = $true ,
                               ValueFromPipeLineByPropertyName=$true)]
                    [ValidateNotNullOrEmpty()]
                    [string]$b,

                    [Parameter(ValueFromPipeLineByPropertyName=$true)]
                    [ValidateNotNullOrEmpty()]
                    [string]$c
                )
                process{}
            }
            BeforeAll {
                $h = @{}
                $h.originalErrorActionPreference = $ErrorActionPreference
                $ErrorActionPreference = 'Stop'
            }
            AfterAll {
                $ErrorActionPreference = $h.originalErrorActionPreference
            }
            It 'ErrorActionPreference is Stop' {
                $ErrorActionPreference | Should be 'Stop'
            }
            It 'does not throw a catchable ParameterBindingException when a mandatory parameter is missing.' {
                $o = New-Object psobject -Property @{a=1}
                $o.a | Should be 1
                {
                    try
                    {
                        $o | f
                    }
                    catch [System.Management.Automation.ParameterBindingException] {}
                } |
                    Should throw
            }
            It 'throws a catchable System.Exception when a mandatory parameter is missing.' {
                $o = New-Object psobject -Property @{a=1}
                $o.a | Should be 1
                try
                {
                    $o | f
                }
                catch [System.Exception]
                {
                    $threw = $true
                }
                $threw | Should be $true
            }
            It 'the System.Exception that is thrown is actually a ParameterBindingException.' {
                $o = New-Object psobject -Property @{a=1}
                $o.a | Should be 1
                try
                {
                    $o | f
                }
                catch [System.Exception]
                {
                    $threw = $true
                    $_.Exception.Message | Should match 'The input object cannot be bound because it did not contain the information required to bind all mandatory parameters:  b'
                    $_.CategoryInfo.Reason | Should be 'ParameterBindingException'

                    # I can't believe this next line passes...
                    $_.Exception -is [System.Management.Automation.ParameterBindingException] | Should be $true
                    # ...poor PowerShell 2 users.
                }
                $threw | Should be $true
            }
            It 'throws on missing mandatory parameter. (terse)' {
                $pparams = @{
                    a = 1
                }
                try
                {
                    $pparams | >> | f
                }
                catch [System.Exception]
                {
                    $threw = $true
                    $_.Exception.Message | Should match 'The input object cannot be bound because it did not contain the information required to bind all mandatory parameters:  b'
                    $_.CategoryInfo.Reason | Should be 'ParameterBindingException'
                }
                $threw | Should be $true
            }
            It 'throws when using both pipeline and named parameter (mandatory param piped)' {
                $pparams = @{
                    a = 1
                }
                    $splat = @{
                    c = 1
                }
                try
                {
                    $pparams | >> | f @splat
                }
                catch [System.Exception]
                {
                    $threw = $true
                    $_.Exception.Message | Should match 'The input object cannot be bound because it did not contain the information required to bind all mandatory parameters:  b'
                    $_.CategoryInfo.Reason | Should be 'ParameterBindingException'
                }
                $threw | Should be $true
            }
            It 'throws when using both pipeline and named parameter (mandatory param splatted)' {
                $pparams = @{
                    c = 1
                }
                    $splat = @{
                    a = 1
                }
                try
                {
                    $pparams | >> | f @splat
                }
                catch [System.Exception]
                {
                    $threw = $true
                    $_.Exception.Message | Should match 'The input object cannot be bound because it did not contain the information required to bind all mandatory parameters:  b'
                    $_.CategoryInfo.Reason | Should be 'ParameterBindingException'
                }
                $threw | Should be $true
            }
        }
        }
        Context ': Proactive conversion to object parameter, function inside module.' {
            $module = New-Module -ScriptBlock {
                function f {
                    [CmdletBinding()]
                    param
                    (
                        [Parameter(Mandatory = $true,
                                   ValueFromPipeLineByPropertyName=$true)]
                        [ValidateNotNullOrEmpty()]
                        [string]$a,

                        [Parameter(Mandatory = $true ,
                                   ValueFromPipeLineByPropertyName=$true)]
                        [ValidateNotNullOrEmpty()]
                        [string]$b,

                        [Parameter(ValueFromPipeLineByPropertyName=$true)]
                        [ValidateNotNullOrEmpty()]
                        [string]$c
                    )
                    process{}
                }
            }
            BeforeAll {
                $h = @{}
                $h.originalErrorActionPreference = $ErrorActionPreference
                $ErrorActionPreference = 'Stop'
            }
            AfterAll {
                $ErrorActionPreference = $h.originalErrorActionPreference
            }
            It 'ErrorActionPreference is Stop' {
                $ErrorActionPreference | Should be 'Stop'
            }
            It 'throws on missing mandatory parameter.' {
                $o = New-Object psobject -Property @{a=1}
                $o.a | Should be 1
                try
                {
                    $o | f -ErrorAction Stop
                }
                catch
                {
                    $threw = $true
                    $_.Exception.Message | Should match 'The input object cannot be bound because it did not contain the information required to bind all mandatory parameters:  b'
                    $_.CategoryInfo.Reason | Should be 'ParameterBindingException'
                }
                $threw | Should be $true
            }
        }
    }
}
Describe 'Properties for different parameter sets in same pipeline.' {
    function f
    {
        [CmdletBinding()]
        param
        (
            [parameter(ParameterSetName = 'a',
                       ValueFromPipelineByPropertyName = $true)]
            $x,

            [parameter(ParameterSetName = 'b',
                       ValueFromPipelineByPropertyName = $true)]
            $y
        )
        process
        {
            return $PSCmdlet.ParameterSetName
        }
    }
    It 'selects correct parameter set for each item in pipeline.' {
        $list = (New-Object psobject -Property @{x=1}),
                (New-Object psobject -Property @{y=1})

        $r = $list | f

        $r[0] | Should be 'a'
        $r[1] | Should be 'b'
    }
    It 'selects correct parameter set for each item in pipeline. (using >>)' {
        $r = @{x=1},@{y=1} | >> | f

        $r[0] | Should be 'a'
        $r[1] | Should be 'b'
    }
}
Describe 'Behavior of PSBoundParameters across pipeline steps.' {
    Context 'PetSerAl''s strategy from https://stackoverflow.com/a/34033842/1404637' {
        function f
        {
            [CmdletBinding()]
            param
            (
                [parameter(ParameterSetName = 'a',
                           ValueFromPipelineByPropertyName = $true)]
                $x,

                [parameter(ParameterSetName = 'b',
                           ValueFromPipelineByPropertyName = $true)]
                $y,

                $z
            )
            begin
            {
                $CommandLineBoundParameters= @{}
                $PSBoundParameters.Keys |
                    % { $CommandLineBoundParameters.$_ = $PSBoundParameters.$_ }
            }
            process
            {
                $PipeLineBoundParameters = @{}
                @($PSBoundParameters.Keys) |
                    ? { $CommandLineBoundParameters.Keys -notcontains $_ } |
                    % {
                        $PipeLineBoundParameters.$_ = $PSBoundParameters.$_
                        [void]$PSBoundParameters.Remove($_)
                    }
                New-Object psobject -Property @{
                    PipelineBoundParameters = $PipeLineBoundParameters
                    CommandLineBoundParameters = $CommandLineBoundParameters
                }
            }
        }
        It 'correctly determines command line parameters.' {
            $list = @{x=1},@{y=2} | % { New-Object psobject -Property $_ }

            $r = $list | f -z 3

            $r[0].CommandLineBoundParameters.Count | Should be 1
            $r[0].CommandLineBoundParameters.z | Should be 3
            $r[1].CommandLineBoundParameters.Count | Should be 1
            $r[1].CommandLineBoundParameters.z | Should be 3
        }
        It 'correctly determines pipeline step parameters.' {
            $list = @{x=1},@{y=2} | % { New-Object psobject -Property $_ }

            $r = $list | f -z 3

            $r[0].PipelineBoundParameters.Count | Should be 1
            $r[0].PipelineBoundParameters.x | Should be 1
            $r[1].PipelineBoundParameters.Count | Should be 1
            $r[1].PipelineBoundParameters.y | Should be 2
        }
    }
}
Describe 'Parameter Set Resolution Ambiguity' {
    function Test-ParameterSetResolution
    {
        [CmdletBinding()]
        param
        (
            [parameter(ParameterSetName = 'A',
                       Mandatory        = $true)]
            [parameter(ParameterSetName = 'B')]
            $Param_2_Ab,

            [parameter(ParameterSetName = 'B',
                       Mandatory        = $true)]
            $Param_3_B
        )
        process
        {
            $PSCmdlet.ParameterSetName
        }
    }
    if ( $PSVersionTable.PSVersion.Major -lt 3 )
    {
        It 'PowerShell 2 always throws trying to resolve to parameter set A' {
            try
            {
                Test-ParameterSetResolution -Param_2_Ab Arg_2_Ab
            }
            catch [System.Exception]
            {
                $threw = $true
                $_.FullyQualifiedErrorId |
                    Should match AmbiguousParameterSet
            }
            $threw | Should be $true
        }
    }
    else
    {
        It 'Resolves to parameter set A' {
            $r = Test-ParameterSetResolution -Param_2_Ab Arg_2_Ab
            $r | Should be 'A'
        }
    }
    It 'Resolves to parameter set B' {
        $r = Test-ParameterSetResolution -Param_3_B Arg_3_B
        $r | Should be 'B'
    }
}
Describe 'Selection of parameter sets when no parameter set is selected' {
    Context 'one parameter set' {
        function test
        {
            [CmdletBinding()]
            param
            (
                $notInSet,

                [parameter(ParameterSetName = 'A')]
                $A
            )
            process
            {
                $PSCmdlet.ParameterSetName
            }
        }
        It 'mentioning a parameter in a set resolves to that parameter set' {
            $r = test -A a
            $r | Should be a
        }
        It 'mentioning only parameters not in parameter sets resolves to __AllParameterSets' {
            $r = test -NotInSet n
            $r | Should be '__AllParameterSets'
        }
        It 'mentioning no parameters resolves to __AllParameters' {
            $r = test
            $r | Should be '__AllParameterSets'
        }
    }
    Context 'two parameter sets' {
        function test
        {
            [CmdletBinding()]
            param
            (
                $notInSet,

                [parameter(ParameterSetName = 'A')]
                $A,

                [parameter(ParameterSetName = 'B')]
                $B
            )
            process
            {
                $PSCmdlet.ParameterSetName
            }
        }
        It 'mentioning a parameter in a set resolves to that parameter set' {
            $r = test -A a
            $r | Should be a
        }
        It 'mentioning only parameters not in parameter sets throws exception' {
            { test -no_set n } |
                Should throw 'Parameter set cannot be resolved'
        }
        It 'mentioning no parameters throws exception' {
            { test } |
                Should throw 'Parameter set cannot be resolved'
        }
    }
    Context 'two parameter sets and "core" set' {
        function test
        {
            [CmdletBinding()]
            param
            (
                [parameter(ParameterSetName = 'core')]
                [parameter(ParameterSetName = 'A')]
                [parameter(ParameterSetName = 'B')]
                $Core,

                [parameter(ParameterSetName = 'A')]
                $A,

                [parameter(ParameterSetName = 'B')]
                $B
            )
            process
            {
                $PSCmdlet.ParameterSetName
            }
        }
        It 'mentioning a parameter in a set resolves to that parameter set' {
            $r = test -A a
            $r | Should be a
        }
        It 'mentioning only parameters in core set throws exception' {
            { test -Core c } |
                Should throw 'Parameter set cannot be resolved'
        }
        It 'mentioning no parameters throws exception' {
            { test } |
                Should throw 'Parameter set cannot be resolved'
        }
    }
    Context 'two parameter sets, "core" set, and default' {
        function test
        {
            [CmdletBinding(DefaultParameterSetName = 'core')]
            param
            (
                [parameter(ParameterSetName = 'core')]
                [parameter(ParameterSetName = 'A')]
                [parameter(ParameterSetName = 'B')]
                $Core,

                [parameter(ParameterSetName = 'A')]
                $A,

                [parameter(ParameterSetName = 'B')]
                $B
            )
            process
            {
                $PSCmdlet.ParameterSetName
            }
        }
        It 'mentioning a parameter in a set resolves to that parameter set' {
            $r = test -A a
            $r | Should be a
        }
        It 'mentioning only parameters in core set resolves to core set' {
            $r = test -Core c
            $r | Should be 'core'
        }
        It 'mentioning no parameters resolves to core set' {
            $r = test
            $r | Should be 'core'
        }
    }
}
Describe 'Select parameter set based on hashtable vs pscustomobject vs string' {
    # see also https://stackoverflow.com/q/39902244/1404637

    Context 'naive attempt' {
        function Test-Discrimination
        {
            [CmdletBinding()]
            param
            (
                [parameter(ValueFromPipeline = $true,
                           Mandatory = $true,
                           ParameterSetName = 'string')]
                [string]
                $String,

                [parameter(ValueFromPipeline = $true,
                           Mandatory = $true,
                           ParameterSetName = 'hashtable')]
                [hashtable]
                $Hashtable,

                [parameter(ValueFromPipeline = $true,
                           Mandatory = $true,
                           ParameterSetName = 'pscustomobject')]
                [pscustomobject]
                $PsCustomObject
            )
            process
            {
                $PSCmdlet.ParameterSetName
            }
        }
        It 'doesn''t resolves to string' {
            { 'string' | Test-Discrimination -ErrorAction Stop } |
                Should throw 'Parameter set cannot be resolved '
        }
        It 'doesn''t resolves to hashtable' {
            { @{} | Test-Discrimination -ErrorAction Stop } |
                Should throw 'Parameter set cannot be resolved '
        }
        It 'resolves to pscustomobject' {
            $r = New-Object pscustomobject | Test-Discrimination
            $r | Should be 'pscustomobject'
        }
    }
    Context 'don''t use type accelerators' {
        function Test-Discrimination
        {
            [CmdletBinding()]
            param
            (
                [parameter(ValueFromPipeline = $true,
                           Mandatory = $true,
                           ParameterSetName = 'string')]
                [System.String]
                $String,

                [parameter(ValueFromPipeline = $true,
                           Mandatory = $true,
                           ParameterSetName = 'hashtable')]
                [System.Collections.Hashtable]
                $Hashtable,

                [parameter(ValueFromPipeline = $true,
                           Mandatory = $true,
                           ParameterSetName = 'pscustomobject')]
                [System.Management.Automation.PSCustomObject]
                $PsCustomObject
            )
            process
            {
                $PSCmdlet.ParameterSetName
            }
        }
        It 'resolves to string' {
            $r = 'string' | Test-Discrimination
            $r | Should be 'string'
        }
        It 'resolves to hashtable' {
            $r = @{} | Test-Discrimination
            $r | Should be 'hashtable'
        }
        It 'doesn''t resolve to pscustomobject' {
            { New-Object pscustomobject | Test-Discrimination -ErrorAction Stop } |
                Should throw "Cannot bind argument to parameter 'String'"
        }
    }
    Context 'don''t use type accelerators, use default parameter set' {
        function Test-Discrimination
        {
            [CmdletBinding(DefaultParameterSetName = 'pscustomobject')]
            param
            (
                [parameter(ValueFromPipeline = $true,
                           Mandatory = $true,
                           ParameterSetName = 'string')]
                [System.String]
                $String,

                [parameter(ValueFromPipeline = $true,
                           Mandatory = $true,
                           ParameterSetName = 'hashtable')]
                [System.Collections.Hashtable]
                $Hashtable,

                [parameter(ValueFromPipeline = $true,
                           Mandatory = $true,
                           ParameterSetName = 'pscustomobject')]
                [System.Management.Automation.PSCustomObject]
                $PsCustomObject
            )
            process
            {
                $PSCmdlet.ParameterSetName
            }
        }
        It 'resolves to string' {
            $r = 'string' | Test-Discrimination
            $r | Should be 'string'
        }
        It 'resolves to hashtable' {
            $r = @{} | Test-Discrimination
            $r | Should be 'hashtable'
        }
        It 'doesn''t resolve to pscustomobject' {
            { New-Object pscustomobject | Test-Discrimination -ErrorAction Stop } |
                Should throw "Cannot bind argument to parameter 'String'"
        }
    }
}
Describe 'pipeline binding to ScriptProperty' {
    $o = New-Object psobject -Property @{ p = 'pval' } |
        Add-Member ScriptProperty 'sp' { 'spval' } -PassThru
    function f {
        [CmdletBinding()]
        param
        (
            [Parameter(ValueFromPipelineByPropertyName = $true)]
            $p,

            [Parameter(ValueFromPipelineByPropertyName = $true)]
            $sp
        )
        process { return $PSBoundParameters }
    }
    It 'pipeline binds normal property by name' {
        $r = $o | f
        $r.p | Should be 'pval'
    }
    It 'pipeline binds script property by name' {
        $r = $o | f
        $r.sp | Should be 'spval'
    }
}
Describe 'no CmdletBinding' {
    function f { param($a) $args }
    It 'resultant command object has CmdletBinding set to false' {
        $r = Get-Command f
        $r.CmdletBinding | Should be $false
    }
    It 'accepts bogusly-name arguments without error' {
        f -bogus
    }
    It 'bogusly-named arguments are collected in $args' {
        $r = f -bogus1 1 -bogus2 2
        $r.Count | Should be 4
        $r[1] | Should be 1
        $r[2] | Should be '-bogus2'
    }
}
Describe 'implicit CmdletBinding' {
    function f { param([Parameter(Mandatory=$true)]$a) }
    It 'using [Parameter()] causes resultant command object to have CmdletBinding set to true' {
        $r = Get-Command f
        $r.CmdletBinding | Should be $true
    }
    It 'bogusly-name arguments throw exceptions' {
        { f -bogus } |
            Should throw 'A parameter cannot be found'
    }
}
Describe 'CmdletBinding and aliases' {
    function f { [CmdletBinding()]param($a) }
    Set-Alias af f
    It 'an alias of a command using CmdletBinding does not have a CmdletBinding attribute' {
        $r = Get-Member CmdletBinding -InputObject (Get-Command af)
        $r | Should beNullOrEmpty
    }
}
Describe 'splats and invokation operator' {
    function f { param($a) $a }
    $splat = @{ a = 1 }
    It 'splat binds to parameter...' {
        $r = f @splat
        $r | Should be 1
    }
    It '...even when invoked using &' {
        $r = & 'f' @splat
        $r | Should be 1
    }
}

Describe 'null passed to string parameter' {
    Context 'no attribute' {
        function f { param([string]$x) $x }
        It 'null becomes string' {
            $r = f -x $null
            $r.GetType() | Should be 'string'
        }
    }
    Context '[AllowNull()]' {
        function f { param ([AllowNull()][string] $x ) $x }
        It 'null becomes string' {
            $r = f -x $null
            $r.GetType() | Should be 'string'
        }
    }
    Context 'no type' {
        function f { param ($x) $x }
        It 'null remains null' {
            $r = f -x $null
            $null -eq $r | Should be $true
        }
    }
    Context '[string[]]' {
        function f { param ([string[]]$x) $x }
        It 'null remains null' {
            $r = f -x $null
            $null -eq $r | Should be $true
        }
    }
}

Describe 'null passed to various parameter types' {
    Add-Type -AssemblyName mscorlib
    $arraylist = [System.Collections.ArrayList]@(
        @([int],0),
        @([System.Nullable[int]],$null),
        @([System.DayOfWeek],'Sunday','throws'),
        @([System.Nullable[System.DayOfWeek]],$null),
        @([hashtable],$null),
        @([array],$null),
        @([string],[string]::Empty),
        @([System.Collections.ArrayList], $null),
        @([System.Collections.BitArray], $null),
        @([System.Collections.SortedList], $null),
        @([System.Collections.Queue], $null),
        @([System.Collections.Stack], $null)
    )
    if ( $PSVersionTable.PSVersion -ge '3.0' )
    {
        $arraylist.Add(@([System.Collections.Generic.Dictionary``2[System.String,int32]],$null))
    }
    foreach ( $values in $arraylist )
    {
        $type, $expectedValue = $values
        $typeName = $type.UnderlyingSystemType
        if ( $null -eq $expectedValue ) { $expectedValueDescription = 'null' }
        elseif ( $expectedValue -eq [string]::Empty )
        {
            $expectedValueDescription = '[string]::Empty'
        }
        else { $expectedValueDescription = $expectedValue }

        Context "parameter type $typeName" {
            Invoke-Expression "function f { param([$typeName]`$x) `$x }"
            if ( $expectedValue -eq 'throws' )
            {
                It '$null throws exception' {
                    { f -x $Null } | Should throw
                }
            }
            else
            {
                It "$name becomes $expectedValueDescription" {
                    $r = f -x $null
                    $r -eq $expectedValue | Should be $true
                }
            }

        }
    }
}

Describe 'behavior of different values passed to [string[]] parameter' {
    Context '[string[]] only' {
        function f {
            param([string[]]$x)
            New-Object psobject -Property @{
                value = $x
                type = if ($x) { $x.GetType() }
            }
        }
        It 'null remains null' {
            $r = f -x $null
            $null -eq $r.value | Should be $true
        }
        It '[string]::empty remains [string]::empty' {
            $r = f -x ([string]::empty)
            [string]::Empty -eq $r.value | Should be $true
        }
        It 'string becomes string[]' {
            $r = f -x 'a'
            $r.type | Should be 'string[]'
        }
        It 'string[] count 1 remains string[] count 1' {
            $r = f -x @('a')
            $r.value.Count | Should be 1
            $r.type | Should be 'string[]'
        }
        It 'string[] count 2 remains string[] count 2' {
            $r = f -x 'a','b'
            $r.value.Count | Should be 2
            $r.type | Should be 'string[]'
        }
    }
}

if ( $PSVersionTable.PSVersion -ge '3.0' )
{
Describe 'behavior of [nullstring]::Value passed to [string] parameter' {
    function f { param( [string]$x ) $x }
    Context 'named parameter' {
        It '[nullstring]::Value becomes [string]::empty' {
            $r = f -x ([NullString]::Value)
            [string]::Empty -eq $r | Should be $true
        }
    }
}
}

Describe '[AllowNull()]' {
    Context 'omit [AllowNull()]' {
        function f {
            [CmdletBinding()]
            param
            (
                [Parameter(ValueFromPipelineByPropertyName=$true)]
                $a,

                [Parameter(Mandatory = $true,
                           ValueFromPipelineByPropertyName=$true)]
                $b
            )
            $PSBoundParameters
        }
        It 'named parameter gets bound' {
            $r = f -a $null -b 's'
            $r.Keys -contains 'a' | Should be $true
        }
        It 'named mandatory parameter does not bind' {
            { f -a 's' -b $null } |
                Should throw 'cannot bind'
        }
        It 'pipeline parameter gets bound' {
            $r = New-Object psobject -Property @{
                a = $null
                b = 's'
            } | f
            $r.Keys -contains 'a' | Should be $true
        }
        It 'mandatory pipeline parameter is not bound...' {
            $r = New-Object psobject -Property @{
                a = 's'
                b = $null
            } | f -ea silent
            $r.Keys -contains 'b' | Should be $false
        }
        It '...and produces a non-terminating error by default.' {
            {
                New-Object psobject -Property @{
                    a = 's'
                    b = $null
                } | f -ea stop
            } |
                Should throw "Cannot bind argument to parameter 'b' because it is null."
        }
    }
    Context '[AllowNull()]' {
        function f {
            [CmdletBinding()]
            param
            (
                [Parameter(Mandatory = $true,
                           ValueFromPipelineByPropertyName=$true)]
                [AllowNull()]
                $a
            )
            $PSBoundParameters
        }
        It 'mandatory pipeline parameter is bound...' {
            $r = New-Object psobject -Property @{
                a = $null
            } | f
            $r.Keys -contains 'a' | Should be $true
        }
        It '...and produces no error.' {
            New-Object psobject -Property @{
                a = $null
            } | f -ea stop
        }
    }
}
