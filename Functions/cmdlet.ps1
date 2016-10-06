Set-Alias gbpm Get-BoundParams
Set-Alias gcp Get-CommonParams
Set-Alias '>>' ConvertTo-ParamObject
Set-Alias icms Invoke-CommandSafely

Function Get-BoundParams
{
<#
.SYNOPSIS
A terse and universal way to get the cmdlet's bound parameters.

.DESCRIPTION
The alias gbpm for Get-BoundParams can be use to obtain the current cmdlet's bound parameters in a terse manner whose value is available even from debuggers.  Get-BoundParams allows for this terse alternative to $PSCmdlet.MyInvocation.BoundParameters:

  &(gbpm)

A test for the existence of a parameter in an advanced function then becomes the following:

  if ( (&(gbpm)).Keys -contains 'SomeParameter' )

You might also consider $PSBoundParameters which is somewhat terser than $PSCmdlet.MyInvocation.BoundParameters but is not available from debuggers (see about_Debuggers and https://stackoverflow.com/q/9025942/1404637).

.OUTPUTS
A scriptblock that evaluates to the cmdlet's bound parameters.

.EXAMPLE
    function f1 {
        [CmdletBinding()]
        param($p1)
        process
        {
            if
            (
                (&(gbpm)).Keys -contains 'p1' -and  # tests existence of parameter
                -not $p1                      # tests value of parameter
            )
            {
                Write-Host 'p1 provided, but false'
            }
        }
    }

    f1 -p1 $false

This demonstrates the difference between testing the value and testing the existence of a parameter.  Get-BoundParams streamlines testing for existence of parameters.

.LINK
about_Debuggers
https://stackoverflow.com/q/9025942/1404637
#>
    [CmdletBinding()]
    param
    (
        # Get-BoundParams normally only provides user-defined parameters.  Set this switch to include common parameters.
        [switch]
        [Alias('cp')]
        $IncludeCommonParameters,

        # Get-BoundParams normally returns a scriptblock.  Set this switch to return the code string used to create the scriptblock, instead.
        [switch]
        $Code
    )
    process
    {
        if ( $IncludeCommonParameters )
        {
            $codeString = "iex '`$PSCmdlet.MyInvocation.BoundParameters'"
        }
        else
        {
            $codeString = @'
                $cp = [System.Management.Automation.PSCmdlet]::CommonParameters
                $bp = iex "`$PSCmdlet.MyInvocation.BoundParameters"
                $ncbp = @{}
                $bp.Keys |
                    ? { $cp -notContains $_ } |
                    % {
                        $ncbp[$_] = $bp[$_]
                    }
                $ncbp

'@
        }
        if ($Code) { return $codeString }
        [scriptblock]::Create($codeString)
    }
}
Function Get-CommonParams
{
<#
.SYNOPSIS
A terse way to get cascade common parameters from one cmdlet to another.

.DESCRIPTION
The alias gcp for Get-CommonParams can be use to cascade the parameters that control output streams from one cmdlet to another.  Get-CommonParams allows for this terse usage:

  $cp = &(gcp)
  Invoke-SomeOtherFunction @cp

.OUTPUTS
A scriptblock that evaluates to the hashtable that, when passed as splat parameters to another cmdlet, cascades the common parameters of the calling cmdlet to that cmdlet.

.EXAMPLE
    function f1 {
        [CmdletBinding()]
        param()
        process
        {
            $cp = &(gcp)
            f2 @cp
        }
    }
    function f2 {
        [CmdletBinding()]
        param()
        process
        {
            Write-Verbose 'This gets output to the Verbose stream.'
        }
    }

    f1 -Verbose

This demonstrates how to use Get-CommonParams to cascade the value and existence of the Verbose switch from cmdlet f1 to cmdlet f2.
#>
    [CmdletBinding()]
    param
    (
        # The list of output stream parameters to cascade
        [parameter(ValueFromPipeline               = $true,
                   Position                        = 1,
                   ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $ParamList = ('Debug','ErrorAction','ErrorVariable','Verbose',
                      'WarningAction','WarningVariable','WhatIf','Confirm'),

        # Get-CommonParams normally returns a scriptblock.  Set this switch to return the code string used to create the scriptblock, instead.
        [switch]
        $Code
    )
    process
    {
        $commonParameters = Get-CommonParameterNames

        if ( (&(gbpm)).Keys -contains 'ParamList' )
        {
            $pl = $ParamList
        }
        else
        {
            $pl = Get-CommonParameterNames
        }

        # get the valid output stream names
        $vcp = $pl |
            % {
                if ( $commonParameters -Contains $_ ) { $_ }
                else
                {
                    Write-Error "`"$_`" is not a valid Common Parameter."
                }

            }
        $codeString = @'
            $hash = @{}

'@
        foreach ($name in $vcp)
        {
            $codeString = $codeString + @"
            if ( `$PSCmdlet.MyInvocation.BoundParameters.Keys -Contains '$name' )
            {
                `$hash['$name'] = `$PSCmdlet.MyInvocation.BoundParameters['$name']
            }

"@
        }
        $codeString = $codeString + @'
            $hash
'@

        if ( $Code ) { return $codeString }

        [scriptblock]::Create($codeString)
    }
}

function NoParams
{
    [CmdletBinding()]
    param()
    process{}
}

Function Get-CommonParameterNames
{
    [CmdletBinding()]
    param()
    process
    {
        if ( $PSVersionTable.PSVersion.Major -gt 3 )
        {
            [System.Management.Automation.PSCmdlet]::CommonParameters+`
            [System.Management.Automation.PSCmdlet]::OptionalCommonParameters
        }
        else
        {
            (Get-Command NoParams).Parameters.Keys
        }
    }
}

function Publish-Failure
{
<#
.SYNOPSIS
A DRY way to implement user-selectable failure actions.

.DESCRIPTION
Publish-Failure throws an exception, reports an error, or a verbose message depending on ErrorActionPrefernce.  This allows implementation of Cmdlets that vary their failure actions without repeating code.  For example, Test-ValidFileName is used in two different ways:

    1. Publicly to test whether a file name is valid.  In this case the user doesn't expect an exception to be thrown if the test fails.
    2. Internally to assert that a file name is valid.  In this case the calling function needs Test-ValidFileName to throw an exception with the detailed reasons for failure, so that the user of the calling function sees the underlying reason for the failure.

Publish-Failure allows both of the above needs to be fulfilled on a single line of code without repetition.  Here is an example:

function Do-Something
{
    param($FileName)

    $FileName | Test-ValidFilename -ErrorAction Stop
    ...
}

Normally Test-ValidFilename returns false on a failure.  However, that behavior would violate one of Scott Hanselman's rules of thumbs for Do-Something:

    "If your functions are named well,
    using verbs (actions) and nouns
    (stuff to take action on) then
    throw an exception if your method
    can't do what it says it can."

Accordingly, we need a failure of Test-ValidFilename to throw an exception rather than just silently continue.  Because we want that exception to contain detailed information about the cause of the failure, Test-ValidFilename's fail behavior needs to be changed to throw using -ErrorAction Stop.  This variability is implemented by Test-ValidFilename by calling Publish-Failure.  Look at the implementation of Test-ValidFilename for an example.
.OUTPUTS
A scriptblock that can be invoked by the caller to publish the failure according to the parameters.  The scriptblock will either contain code that throws an exception, calls Write-Error, or Write-Verbose.

.LINK
http://www.hanselman.com/blog/GoodExceptionManagementRulesOfThumb.aspx
Test-ValidFileName
#>
    [CmdletBinding()]
    param
    (
        # The list of arguments for the exception when ErrorAction is Stop. The first element is used as the message when ErrorAction is Continue or SilentlyContinue.
        [Parameter(Mandatory                       = $true,
                   Position                        = 1,
                   ValueFromPipelineByPropertyName = $true)]
        [string[]]
        $ArgumentList='Unspecified Error',

        # the type of exception to throw for ErrorAction Stop
        [Parameter(Position                        = 2,
                   ValueFromPipelineByPropertyName = $true)]
        [Type]
        $ExceptionType=[System.Exception],

        # By default, output is Verbose when ErrorAction is Continue.  Use this switch to Write-Error when ErrorAction is Continue.
        [switch]
        $AllowError,

        # output the resulting scriptblock as code instead
        [switch]
        $AsCode
    )
    process
    {
        if (-not $PSBoundParameters.ContainsKey('ErrorActionPreference'))
        {
            $ErrorActionPreference = $PSCmdlet.GetVariableValue('ErrorActionPreference')
        }

        switch ($ErrorActionPreference) {
            'Continue' {
                if ( $AllowError )
                {
                    $code = "Write-Error '$($ArgumentList[0])'"
                }
                else
                {
                    $code = "Write-Verbose '$($ArgumentList[0])'"
                }
            }
            'SilentlyContinue' {
                $code = "Write-Verbose '$($ArgumentList[0])'"
            }
            'Stop' {
                $argumentListString = ConvertTo-PsLiteralString $ArgumentList
                $code = "throw New-Object -TypeName $ExceptionType -ArgumentList $argumentListString"
            }
        }

        if ( $AsCode )
        {
            return $code
        }

        return [scriptblock]::Create($code)
    }
}
Function ConvertTo-ParamObject
{
    [CmdletBinding()]
    param
    (
        [parameter(Position          = 1,
                   Mandatory         = $true,
                   ValueFromPipeline = $true)]
        [AllowNull()]
        $InputObject
    )
    process
    {
        if ( $null -eq $InputObject )
        {
            return
        }
        if
        (
            # the usual type of splat parameters
            $InputObject -is [hashtable] -or

            # the type of PSBoundParameters
            ([string]$InputObject.GetType()) -eq 'System.Collections.Generic.Dictionary[string,System.Object]'
        )
        {
            return New-Object psobject -Property $InputObject
        }

        return $InputObject
    }
}

if ( $PSVersionTable.PSVersion.Major -ge 4)
{
function Get-Parameters
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position                        = 1,
                   Mandatory                       = $true,
                   ValueFromPipeline               = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [string]
        $CmdletName,

        [Parameter(Position                        = 2,
                   ValueFromPipelineByPropertyName = $true)]
        [string]
        $ParameterSetName,

        [Parameter(Position                        = 3,
                   ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('Required','All')]
        [string]
        $Mode='All'
    )
    process
    {
        $bp = &(gbpm)

        $cmd = Get-Command $CmdletName -ErrorAction Stop

        if
        (
             $bp.Keys -notcontains 'ParameterSetName' -and
            $cmd.ParameterSets.Count -gt 1 -and
            -not $cmd.DefaultParameterSet
        )
        {
            throw New-Object System.ArgumentException(
                "Cmdlet $CmdletName has more than one parameterset and no default. You must provide ParameterSetName.",
                'ParameterSetName'
            )
        }

        if
        (
            $bp.Keys -contains 'ParameterSetName' -and
            ($cmd.ParameterSets | % {$_.Name}) -notcontains $ParameterSetName
        )
        {
            throw New-Object System.ArgumentException(
                "Cmdlet $CmdletName does not have ParameterSetName $ParameterSetName.",
                'ParameterSetName'
            )
        }

        if ( -not ($cmd.Parameters.Keys | ? { (Get-CommonParameterNames) -notcontains $_}))
        {
            return
        }

        if
        (
            $bp.Keys -notcontains 'ParameterSetName' -and
            $cmd.DefaultParameterSet
        )
        {
            $psn = $cmd.DefaultParameterSet
        }

        if
        (
            $bp.Keys -notcontains 'ParameterSetName' -and
            -not $cmd.DefaultParameterSet
        )
        {
            $psn = $cmd.ParameterSets[0].Name
        }

        if
        (
            $bp.Keys -contains 'ParameterSetName'
        )
        {
            $psn = $ParameterSetName
        }

        $parameterSet = $cmd.ParameterSets | ? { $_.Name -eq $psn }
        $parameterSetParameterNames = $parameterSet.Parameters |
            ? { (Get-CommonParameterNames) -notcontains $_.Name } |
            % {$_.Name}

        $help = Get-Help $CmdletName

        return $help.parameters.parameter |
            ? {
                (
                    $_.Required -eq $true -or
                    $Mode -eq 'All'
                ) -and
                $parameterSetParameterNames -contains $_.Name
            } |
            % {$_.Name}
    }
}
function Test-ValidParams
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position                        = 1,
                   Mandatory                       = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [string]
        $CmdletName,

        [Parameter(Position                        = 2,
                   Mandatory                       = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [hashtable]
        $SplatParams,

        [Parameter(Position                        = 3,
                   ValueFromPipelineByPropertyName = $true)]
        [string]
        $ParameterSetName
    )
    process
    {
        foreach ( $requiredParam in (&(gbpm) | >> | Get-Parameters -Mode Required) )
        {
            if ( $SplatParams.Keys -notcontains $requiredParam )
            {
                $message = "Required parameter $requiredParam not in SplatParams for Cmdlet $CmdletName"
                $param = $requiredParam
            }
        }

        $allParams = (&(gbpm) | >> | Get-Parameters -Mode All)

        foreach ( $splatParam in $SplatParams.Keys )
        {
            if (  $allParams -notcontains $splatParam )
            {
                $message = "SplatParam $splatParam provided but not a parameter of Cmdlet $CmdletName"
                $param = $splatParam
            }
        }

        if ($message)
        {
            Switch ($ErrorActionPreference) {
                'Stop' {
                    throw New-Object System.ArgumentException(
                        $message,
                        $param
                    )
                }
                'Continue'   { Write-Error   $message}
                'SilentlyContinue' { Write-Verbose $message }
            }
            return $false
        }

        return $true
    }
}
function Invoke-CommandSafely
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position                        = 1,
                   Mandatory                       = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [string]
        $CmdletName,

        [Parameter(Position                        = 2,
                   Mandatory                       = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [hashtable]
        $SplatParams,

        [Parameter(Position                        = 3,
                   ValueFromPipelineByPropertyName = $true)]
        [string]
        $ParameterSetName
    )
    process
    {
        $bp = &(gbpm)
        Test-ValidParams @bp -ErrorAction Stop | Out-Null

        & $CmdletName @SplatParams
    }
}
}
