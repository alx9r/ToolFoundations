function Compare-Object2
{
<#
.SYNOPSIS
An alternative to Compare-Object with better handling of edge-cases.

.DESCRIPTION
Compare-Object2 behaves like Compare-Object in straightforward cases.  Compare-Object2, however, differs from Compare-Object in its handling of the following cases:

Null Objects
============
Compare-Object throws an exception if null is provided for either the reference or difference objects.  Compare-Object2 treats null difference and reference objects as empty lists.

Shape of PassThru Arrays
========================
When using PassThru with multiple DifferenceObjects, Compare-Object produces a one-dimensional array.  Compare-Object2 uses Out-Collection to selectively wrap DifferenceObjects in sacrificial arrays (to compensate for pipeline unrolling) such that an array of arrays that differ results.

.OUTPUTS
An array of difference objects with properties InputObject and SideIndicator or, if PassThru is set, each DifferenceObject that differs from ReferenceObject.

.LINKS
  http://stackoverflow.com/q/15487623/1404637
  Compare-Object
#>
    [CmdletBinding()]
    param
    (
        # Same as ReferenceObject parameter of Compare-Object except that null is treated as an empty list.
        [Parameter( Position=1,
                    Mandatory=$true)]
        [AllowNull()]
        [PSObject[]]
        $ReferenceObject,

        # Same as DifferenceObject parameter of Compare-Object except that null is treated as an empty list.
        [Parameter( Position=2,
                    Mandatory=$true,
                    ValueFromPipeline=$true)]
        [AllowNull()]
        [PSObject[]]
        $DifferenceObject,

        # Same as Compare-Object.
        [switch]
        $CaseSensitive,

        # Same as Compare-Object.
        [string]
        $Culture=$null,

        # Same as PassThru parameter of Compare-Object except that an array of arrays that differ is output rather than a single one-dimensional array.
        [switch]
        $PassThru,

        # Same as Compare-Object
        [Int32]
        $SyncWindow=[Int32]::MaxValue
    )
    begin
    {
        if ( $PassThru )
        {
            $acc = New-Object System.Collections.ArrayList
        }
    }
    process
    {
        # handle two null objects
        if
        (
            -not $PassThru             -and
            $null -eq $ReferenceObject -and
            $null -eq $DifferenceObject
        )
        {
            return $null
        }

        # handle producing diff of one null object
        if
        (
            -not $PassThru              -and
            (
                $null -eq $ReferenceObject  -or
                $null -eq $DifferenceObject
            )
        )
        {
            if ( $null -eq $ReferenceObject ) { $side = '=>'; $obj = $DifferenceObject }
            else                              { $side = '<='; $obj = $ReferenceObject  }

            $obj |
                % {
                    New-Object PSObject @{
                        InputObject   = $_
                        SideIndicator = $side
                    }
                }
            return
        }

        if ( -not $PassThru )
        {
            # this case is handled correctly by Compare-Object
            Compare-Object `
                -ReferenceObject  $ReferenceObject `
                -DifferenceObject $DifferenceObject `
                -SyncWindow       $SyncWindow `
                -Culture          $Culture `
                -CaseSensitive:$CaseSensitive
            return
        }


        # we are dealing with PassThru down here
        if
        (
            $null -eq $ReferenceObject  -and
            $null -eq $DifferenceObject
        )
        {
            # they match, so emit nothing
            return
        }
        if
        (
            $null -eq $ReferenceObject  -or
            $null -eq $DifferenceObject
        )
        {
            # they differ, so emit the difference object
            $acc.Add($DifferenceObject) | Out-Null
            return
        }

        $r = Compare-Object `
                -ReferenceObject  $ReferenceObject `
                -DifferenceObject $DifferenceObject `
                -SyncWindow       $SyncWindow `
                -Culture          $Culture `
                -CaseSensitive:$CaseSensitive

        if ( $r )
        {
            # they differ, so emit the difference object
            $acc.Add($DifferenceObject) | Out-Null
            return
        }
    }
    end
    {
        if ( $PassThru )
        {
            Out-Collection ([array]$acc)
        }
    }
}
