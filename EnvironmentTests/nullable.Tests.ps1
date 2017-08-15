if ( $PSVersionTable.PSVersion -lt '3.0.0' )
{
    return
}

Add-Type "public enum Triple_8c166bf8 { one, two, three }"

Describe 'nullable enum' {
    Context 'plain' {
        It 'instantiate' {
            New-Object Triple_8c166bf8
        }
        It 'defaults to first value' {
            $r = New-Object Triple_8c166bf8
            $r | Should be 'one'
        }
        It 'cannot cast null to enum' {
            { [Triple_8c166bf8]$null } |
                Should throw 'Cannot convert null to type'
        }
    }
    Context 'nullable' {
        It 'instantiate' {
            New-Object System.Nullable[Triple_8c166bf8]
        }
        It 'instantiation results in null' {
            $r = New-Object System.Nullable[Triple_8c166bf8]
            $r | Should beNullOrEmpty
        }
        It 'can cast null to enum' {
            $r = [System.Nullable[Triple_8c166bf8]]$null
            $r | Should beNullOrEmpty
        }
        It 'can cast string to enum' {
            $r = [System.Nullable[Triple_8c166bf8]]'three'
            $r | Should be 'three'
        }
    }
}
