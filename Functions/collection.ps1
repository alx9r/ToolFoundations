$TypeNotTested = @'
An object of type $InputObjectTypeA $InputObjectTypeB was passed to Out-Collection that is [ienumerable] and whose type's behavior has not been tested for compliance with the output invariants of the Out-Collection.
'@

Function Out-Collection
{
<#
.SYNOPSIS
Packages objects such that they pass through the PowerShell pipeline in a consistent manner.

.DESCRIPTION
Collection objects suffer from two inconsistensies in PowerShell.  First, some are unrolled by the pipeline while others are not.  Second, some empty collections evaluate to true while others evaluate to false.  Out-Collection makes this behavior more consistent by preventing unrolling and ensuring that empty collections evaluate to false.

The PowerShell pipeline unrolls some collection objects.  Out-Collection selectively packages InputObject in a sacrificial array such that it can be safely passed through the PowerShell pipeline without unrolling InputObject.  If InputObject is not a type that is unrolled by the PowerShell pipeline, Out-Collection passes InputObject without a sacrificial array.

The rules that PowerShell follows to decide which objects to unroll are arcane:

https://stackoverflow.com/a/28707054/1404637

Accordingly, while Out-Collection correctly handles many common collections types, it is probably not comprehensive in its coverage.  Out-Collection produces a warning when it determines that InputObject is of a type with which it has not been tested.

.OUTPUTS
Null, InputObject, or InputObject wrapped in a sacrificial array.

.EXAMPLE
    Function TwoOutputsRaw { $args[0]; $args[0] }
    Function TwoOutputsUsingOutCollection {
        Out-Collection $args[0]
        Out-Collection $args[0]
    }

    $r = TwoOutputsRaw 10,'ten'
    # $r is a 4x1 array

    $oc = TwoOutputsUsingOutCollection 10,'ten'
    # $oc is a 2x2 array

Emitting multiple collections into the pipeline sometimes results in unrolling and concatenation of the items into a single array.  Emitting multiple collections using Out-Collection causes an array of the emitted collections to result instead.
.LINK
https://stackoverflow.com/a/28707054/1404637
#>
    [CmdletBinding()]
    param
    (
        # The collection object that needs to be preserved when it passes through the powershell pipeline.
        [parameter(Position=1,
                   Mandatory = $true,
                   ValueFromPipeline=$false)]
        $InputObject,

        # allow null or empty objects to be emitted
        [switch]
        $AllowNullOrEmpty
    )
    process
    {
        #https://stackoverflow.com/q/28702588/1404637

        if ( -not ($InputObject -is [collections.ienumerable]) )
        {
            return $InputObject
        }

        if ( $InputObject -is [string] )
        {
            if ( $InputObject.Length -or $AllowNullOrEmpty )
            {
                return ,$InputObject
            }
            return $null
        }

        if ( $InputObject -is [array] )
        {
            ,$InputObject
            return
        }

        if
        (
            $InputObject -is [hashtable] -or
            $InputObject -is [System.Collections.SortedList] -or
            $InputObject.GetType().FullName -match '^System.Collections.Generic.Dictionary'
        )
        {
            $InputObject.Count -or $AllowNullOrEmpty |
                ?: $InputObject $null
            return
        }

        if
        (
            $InputObject -is [System.Collections.BitArray] -or
            $InputObject -is [System.Collections.Queue] -or
            $InputObject -is [System.Collections.Stack] -or
            $InputObject -is [System.Collections.ArrayList] -or
            $InputObject.GetType().FullName -match '^System.Collections.Generic.List'
        )
        {
            if
            (
                -not $InputObject.Count -and
                -not $AllowNullOrEmpty
            )
            {
                return $null
            }

            if ( -not $InputObject.Count -and $PSVersionTable.PSVersion -lt '3.0' )
            {
                ,(,$InputObject)
                return
            }

            return ,$InputObject
        }

        if ( -not $InputObject -is [System.Xml.XmlElement] )
        {
            $InputObjectTypeA = $InputObject.GetType().FullName
            $InputObjectTypeB = $InputObject.GetType().BaseType.GetType().FullName
            Write-Warning (&($TypeNotTested | xs))
        }

        return $InputObject
    }
}

function New-GenericObject
{
<#
.SYNOPSIS
Creates an object of a generic type.

.DESCRIPTION

.OUTPUTS
Generic object of type name GenericTypeName with parameters TypeParameters.

.EXAMPLE
# Simple generic collection
$list = New-GenericObject System.Collections.ObjectModel.Collection System.Int32
.EXAMPLE
# Generic dictionary with two types
New-GenericObject System.Collections.Generic.Dictionary System.String,System.Int32
.EXAMPLE
# Generic list as the second type to a generic dictionary
$secondType = New-GenericObject System.Collections.Generic.List Int32
New-GenericObject System.Collections.Generic.Dictionary System.String,$secondType.GetType()
.EXAMPLE
# Generic type with a non-default constructor
New-GenericObject System.Collections.Generic.LinkedListNode System.Int32 10
.LINK
http://stackoverflow.com/a/185174/1404637
#>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $GenericTypeName,

        [Parameter(Mandatory = $true)]
        [type[]]
        $TypeParameters,

        [object[]]
        $ConstructorParameters
    )

    ## Create the generic type name
    $genericType = [Type] ($GenericTypeName + '`' + $TypeParameters.Count)

    if(-not $genericType)
    {
        throw "Could not find generic type $genericTypeName"
    }

    ## Bind the type arguments to it
    $closedType = $genericType.MakeGenericType($TypeParameters)
    if(-not $closedType)
    {
        throw "Could not make closed type $genericType"
    }

    ## Create the closed version of the generic type
    Out-Collection ([Activator]::CreateInstance($closedType, $ConstructorParameters)) -AllowNullOrEmpty
}
