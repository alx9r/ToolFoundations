Describe 'combine arrays' {
    Context 'addition' {

        # The addition operator suffers from exceptions when the LHS is
        # not an array.

        It 'two arrays' {
            $r = @(1,2)+(3,4)

            $r.Count | Should be 4
            $r[0] | Should be 1
            $r[3] | Should be 4
        }
        It 'array and int' {
            $r = @(1,2)+3
            $r.Count | Should be 3
            $r[0] | Should be 1
            $r[2] | Should be 3
        }
        It 'int and array' {
            {$r = 1 + @(2,3)} | Should throw
        }
        It 'array and null' {
            $r = @(1,2)+$null
            $r.Count | Should be 3
            $r[0] | Should be 1
            $r[2] | Should beNullOrEmpty
        }
        It 'null and array' {
            $r = $null + @(1,2)
            $r.Count | Should be 2
            $r[0] | Should be 1
            $r[1] | Should be 2
        }
    }
    Context 'comma' {
        
        # The comma operator doesn't combine lists, rather it
        # creates lists of objects which could themselves be
        # lists.

        It 'two arrays' {
            $r = @(1,2),@(3,4)
            $r.Count | Should be 2
            $r[0][0] | Should be 1
            $r[1][1] | Should be 4
        }
        It 'array and int' {
            $r = @(1,2),3
            $r.Count | Should be 2
            $r[0][0] | Should be 1
            $r[1] | Should be 3
        }
        It 'int and array' {
            $r = 1,@(2,3)
            $r.Count | Should be 2
            $r[0] |Should be 1
            $r[1][1] | Should be 3
        }
        It 'array and null' {
            $r = @(1,2),$null
            $r.Count | Should be 2
            $r[0][0] | Should be 1
            $r[1] | Should beNullOrEmpty
        }
        It 'null and array' {
            $r = $null,@(1,2)
            $r.Count | Should be 2
            $r[0] | Should beNullOrEmpty
            $r[1][1] | Should be 2
        }    
    }
    Context 'array operator and comma' {

        # Using the array operator with a comma behaves exactly
        # the same as using just the comma.

        It 'two arrays' {
            $r = @(@(1,2),@(3,4))
            $r.Count | Should be 2
            $r[0][0] | Should be 1
            $r[1][1] | Should be 4
        }
        It 'array and int' {
            $r = @(@(1,2),3)
            $r.Count | Should be 2
            $r[0][0] | Should be 1
            $r[1] | Should be 3
        }
        It 'int and array' {
            $r = @(1,@(2,3))
            $r.Count | Should be 2
            $r[0] |Should be 1
            $r[1][1] | Should be 3
        }
        It 'array and null' {
            $r = @(@(1,2),$null)
            $r.Count | Should be 2
            $r[0][0] | Should be 1
            $r[1] | Should beNullOrEmpty
        }
        It 'null and array' {
            $r = @($null,@(1,2))
            $r.Count | Should be 2
            $r[0] | Should beNullOrEmpty
            $r[1][1] | Should be 2
        }    
    }
    Context 'array operator and whitespace' {

        # Array operator and whitespace causes arrays to be unrolled
        # and recombined with other objects in the array to result in
        # an array.

        It 'two arrays' {
            $r = @(
                @(1,2)
                (3,4)
            )
            $r.Count | Should be 4
            $r[0] | Should be 1
            $r[3] | Should be 4
        }
        It 'two arraylists' {
            $r = @(
                [System.Collections.ArrayList]@(1,2)
                [System.Collections.ArrayList]@(3,4)
            )
            $r -is [Array] | Should be $true
            $r.Count | Should be 4
            $r[0] | Should be 1
            $r[3] | Should be 4
        }
        It 'array and int' {
            $r = @(
                @(1,2)
                3
            )
            $r.Count | Should be 3
            $r[0] | Should be 1
            $r[2] | Should be 3
        }
        It 'int and array' {
            $r = @(
                1
                @(2,3)
            )
            $r.Count | Should be 3
            $r[0] | Should be 1
            $r[2] | Should be 3
        }
        It 'array and null' {
            $r = @(
                @(1,2)
                $null
            )
            $r.Count | Should be 3
            $r[0] | Should be 1
            $r[2] | Should beNullOrEmpty
        }
        It 'null and array' {
            $r = @(
                $null
                @(1,2)
            )
            $r.Count | Should be 3
            $r[0] | Should beNullOrEmpty
            $r[2] | Should be 2
        }    
    }
    Context 'comma and pipe' {

        # Command pipe behaves in exactly the same way as
        # array operator and whitespace.

        It 'two arrays' {
            $r = @(1,2),@(3,4) | % {$_}
            $r.Count | Should be 4
            $r[0] | Should be 1
            $r[3] | Should be 4
        }
        It 'two arraylists' {
            $r = @(
                [System.Collections.ArrayList]@(1,2)
                [System.Collections.ArrayList]@(3,4)
            )
            $r -is [Array] | Should be $true
            $r.Count | Should be 4
            $r[0] | Should be 1
            $r[3] | Should be 4
        }
        It 'array and int' {
            $r = @(1,2),3 | % {$_}
            $r.Count | Should be 3
            $r[0] | Should be 1
            $r[2] | Should be 3
        }
        It 'int and array' {
            $r = 1,@(2,3) | % {$_}
            $r.Count | Should be 3
            $r[0] | Should be 1
            $r[2] | Should be 3
        }
        It 'array and null' {
            $r = @(1,2),$null | % {$_}
            $r.Count | Should be 3
            $r[0] | Should be 1
            $r[2] | Should beNullOrEmpty
        }
        It 'null and array' {
            $r = $null,@(1,2) | % {$_}
            $r.Count | Should be 3
            $r[0] | Should beNullOrEmpty
            $r[2] | Should be 2
        }    
    }
}