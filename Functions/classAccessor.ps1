if ( $PSVersionTable.PSVersion -ge '5.0' )
{
function Get-AccessorPropertyName
{
    [CmdletBinding()]
    [OutputType([string])]
    param
    (
        [Parameter(ValueFromPipeline = $true)]
        [string]
        $String
    )
    process
    {
        # check for missing underscore
        $regex = [regex]'\$(?!_)(?<PropertyName>\w*)\s*=\s*'
        $match = $regex.Match($String)
        if ( $match.Success )
        {
            throw [System.FormatException]::new(
                "Missing underscore in property name at`r`n$String"
            )
        }

        # the main match
        $regex = [regex]'\$_(?<PropertyName>\w*)\s*=\s*'
        $match = $regex.Match($String)
        (ConvertFrom-RegexNamedGroupCapture -Match $match -Regex $regex).PropertyName
    }
}

function Accessor
{
    [CmdletBinding()]
    param
    (
        [Parameter(position=1, Mandatory = $true)]
        $Object,

        [Parameter(position=2, Mandatory = $true)]
        [scriptblock]
        $Scriptblock
    )
    process
    {
        # extract the property name
        $propertyName = $MyInvocation.Line | Get-AccessorPropertyName


        # Prepare the get and set functions that are invoked
        # inside the scriptblock passed to Accessor.
        $functions = @{
            getFunction = {
                param
                (
                    $Scriptblock = (
                        # default getter
                        Invoke-Expression "{`$this._$propertyName}"
                    )
                )
                return New-Object psobject -Property @{
                    Accessor = 'get'; Scriptblock = $Scriptblock
                }
            }
            setFunction = [scriptblock]::Create({
                param
                (
                    $Scriptblock = (
                        # default setter
                        Invoke-Expression "{param(`$p) `$this._$propertyName = `$p}"
                    )
                )
                return New-Object psobject -Property @{
                    Accessor = 'set'; Scriptblock = $Scriptblock
                }
            })
        }

        # Prepare the variables that are available inside the
        # scriptblock that is passed to the accessor.
        $this = $Object
        $__propertyName = $propertyName
        $variables = Get-Variable 'this','__propertyName'

        # avoid a naming collision with the set and get aliases
        Remove-Item alias:\set -ErrorAction Stop
        Set-Alias set setFunction
        Set-Alias get getFunction

        # invoke the scriptblock
        $items = $MyInvocation.MyCommand.Module.NewBoundScriptBlock(
            $Scriptblock
        ).InvokeWithContext($functions,$variables)

        # This empty getter is invoked when no get statement is
        # included in Accessor.
        $getter = {}


        $initialValue = [System.Collections.ArrayList]::new()
        foreach ( $item in $items )
        {
            # get the initializer values
            if ( 'get','set' -notcontains $item.Accessor )
            {
                $initialValue.Add($item) | Out-Null
            }

            # extract the getter
            if ( $item.Accessor -eq 'get' )
            {
                $getter = $item.Scriptblock
            }

            # extract the setter
            if ( $item.Accessor -eq 'set' )
            {
                $setter = $item.Scriptblock
            }
        }

        # If there is no getter or setter don't add a scriptproperty.
        if ( -not $getter -and -not $setter )
        {
            return $initialValue
        }

        # Prepare to create the scriptproperty.
        $splat = @{
            MemberType = 'ScriptProperty'
            Name = $propertyName
            Value = $getter
        }

        # Omit the setter parameter if it is null.
        if ( $setter )
        {
            $splat.SecondValue = $setter
        }

        # Add the accessors by creating a scriptproperty.
        $Object | Add-Member @splat | Out-Null

        # Return the initializers.
        return $initialValue
    }
}
}
