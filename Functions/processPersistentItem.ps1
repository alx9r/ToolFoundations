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
        $Getter,

        [Parameter(Mandatory = $true)]
        [string]
        $Adder,

        [Parameter(Mandatory = $true)]
        [string]
        $Remover,

        [Parameter(ParameterSetName = 'with_properties',
                   Mandatory = $true)]
        [hashtable]
        $Properties,

        [Parameter(ParameterSetName = 'with_properties',
                   Mandatory = $true)]
        [string]
        $PropertySetter,


        [Parameter(ParameterSetName = 'with_properties',
                   Mandatory = $true)]
        [string]
        $PropertyTester
    )
    process
    {
        # retrieve the item
        $item = & $Getter @_Keys

        # process item existence
        switch ( $Ensure )
        {
            'Present' {
                if ( -not $item )
                {
                    # add the item
                    switch ( $Mode )
                    {
                        'Set'  { $item = & $Adder @_Keys } # create the item
                        'Test' { return $false }              # the item doesn't exist
                    }
                }
            }
            'Absent' {
                switch ( $Mode )
                {
                    'Set'  {
                        if ( $item )
                        {
                            & $Remover @_Keys | Out-Null
                        }
                        return
                    }
                    'Test' { return -not $item }
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
            PropertySetter = $PropertySetter
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
        $PropertySetter,

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
                & $PropertySetter @_Keys -PropertyName $propertyName -Value $desired |
                    Out-Null
            }
        }

        if ( $Mode -eq 'Test' )
        {
            return $true
        }
    }
}
