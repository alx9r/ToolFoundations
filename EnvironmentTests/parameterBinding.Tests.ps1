Import-Module ToolFoundations -Force

InModuleScope ToolFoundations {
    Describe 'avoid prompt on missing mandatory parameter (https://stackoverflow.com/questions/33600279)' {
        Context ': reproduce the problem (uncomment the line to cause blocking)' {
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
    }
}
