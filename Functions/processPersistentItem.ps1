function Invoke-ProcessPersistentItem
{
    [CmdletBinding(DefaultParameterSetName = '__AllParameterSets')]
    param
    (
        [Parameter(Mandatory = $true,
                   Position = 1,
                   ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('Set','Test')]
        $Mode,

        [Parameter(Position = 2,
                   ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('Present','Absent')]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true,
                   Position = 3,
                   ValueFromPipeline = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [Alias('Keys')]
        [hashtable]
        $_Keys,  # https://github.com/pester/Pester/issues/776

        [Parameter(Mandatory = $true)]
        [string]
        $Tester,

        [Parameter(Mandatory = $true)]
        [string]
        $Curer,

        [hashtable]
        $CurerParams = @{},

        [string]
        $Remover,

        [Parameter(ParameterSetName = 'with_properties',
                   Mandatory = $true)]
        [hashtable]
        $Properties,

        [Parameter(ParameterSetName = 'with_properties',
                   Mandatory = $true)]
        [string]
        $PropertyCurer,


        [Parameter(ParameterSetName = 'with_properties',
                   Mandatory = $true)]
        [string]
        $PropertyTester
    )
    process
    {
        # confirm remover is present when necessary
        if ( $Mode -eq 'Set' -and $Ensure -eq 'Absent' -and -not $Remover )
        {
            throw 'Invoked "Set Absent" but no remover was provided.'
        }

        # retrieve the item
        $correct = & $Tester @_Keys

        # process item existence
        switch ( $Ensure )
        {
            'Present' {
                if ( -not $correct )
                {
                    # add the item
                    switch ( $Mode )
                    {
                        'Set'  { $item = & $Curer @_Keys @CurerParams } # cure the item
                        'Test' { return $false }           # the item doesn't exist
                    }
                }
            }
            'Absent' {
                switch ( $Mode )
                {
                    'Set'  {
                        if ( $correct )
                        {
                            & $Remover @_Keys | Out-Null
                        }
                        return
                    }
                    'Test' { return -not $correct }
                }
            }
        }

        if ( $PSCmdlet.ParameterSetName -ne 'with_properties' )
        {
            # we are not processing properties
            if ( $Mode -eq 'Test' )
            {
                return $true
            }
            return
        }

        # process the item's properties
        $splat = @{
            Mode = $Mode
            Keys = $_Keys
            Properties = $Properties
            PropertyCurer = $PropertyCurer
            PropertyTester = $PropertyTester
        }
        Invoke-ProcessPersistentItemProperty @splat
    }
}

function Invoke-ProcessPersistentItemProperty
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true,
                   Position = 1)]
        [ValidateSet('Set','Test')]
        $Mode,

        [Parameter(Mandatory = $true)]
        [Alias('Keys')]
        [hashtable]
        $_Keys, # https://github.com/pester/Pester/issues/776

        [hashtable]
        $Properties,

        [Parameter(Mandatory = $true)]
        [string]
        $PropertyCurer,

        [Parameter(Mandatory = $true)]
        [string]
        $PropertyTester
    )
    process
    {
        # process each property
        foreach ( $propertyName in $Properties.Keys )
        {
            # this is the desired value provided by the user
            $desired = $Properties.$propertyName

            # test for the desired value
            $alreadyCorrect = & $PropertyTester @_Keys -PropertyName $propertyName -Value $desired

            if ( -not $alreadyCorrect )
            {
                if ( $Mode -eq 'Test' )
                {
                    # we're testing and we've found a property mismatch
                    return $false
                }

                # the existing property does not match the desired property
                # so fix it
                & $PropertyCurer @_Keys -PropertyName $propertyName -Value $desired |
                    Out-Null
            }
        }

        if ( $Mode -eq 'Test' )
        {
            return $true
        }
    }
}
