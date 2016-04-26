Import-Module ToolFoundations -Force

Describe 'Should2 beGreaterThan'{
    foreach ( $small in @(1,'1',1.0) )
    {
        foreach ( $large in @(2,'2',2.0) )
        {
            Context "Small: [$($small.GetType().Name)]$small Large: [$($large.GetType().Name)]$large" {
                It 'small -gt large throws.' {
                    {$small | Should BeGreaterThan $large} |
                        Should throw
                }
                It 'large -gt small' {
                    $large | Should BeGreaterThan $small
                }
            }
        }
    }
    foreach ( $a in @(1,'1',1.0) )
    {
        foreach ( $b in @(1,'1',1.0) )
        {
            Context "a: [$($a.GetType().Name)]$a b: [$($b.GetType().Name)]$b" {
                It 'small -gt large throws.' {
                    {$a | Should BeGreaterThan $b} |
                        Should throw
                }
            }
        }
    }

    Context 'Dates' {
        $small = Get-Date -Year 2000 -Month 1 -Day 1
        $large = Get-Date -Year 2001 -Month 1 -Day 1
        It 'small -gt large throws.' {
            {$small | Should BeGreaterThan $large} |
                Should throw
        }
        It 'large -gt small' {
            $large | Should BeGreaterThan $small
        }
    }
}
