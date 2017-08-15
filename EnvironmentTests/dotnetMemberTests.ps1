Describe '.Net types as PowerShell class members' {
    Context 'enum' {
        It 'instantiate' {
            New-Object Triple_b3f43f68
        }
        It 'instantiate a PowerShell class with .Net enum as a member' {
            class c {
                [Triple_b3f43f68] $e
            }
            New-Object Triple_b3f43f68
        }
    }
    Context 'class' {
        It 'instantiate' {
            New-Object Widget_b3f43f68
        }
        It 'instantiate a PowerShell class with .Net class as a member' {
            class c {
                [Widget_b3f43f68] $w
            }
            New-Object Widget_b3f43f68
        }
    }
}
