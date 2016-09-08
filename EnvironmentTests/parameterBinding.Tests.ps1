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
Describe 'Parameter Set Resolution' {
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
