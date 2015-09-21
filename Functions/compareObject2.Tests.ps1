Describe Compare-Object2 {
    BeforeEach {
        Remove-Module ToolFoundations -ea SilentlyContinue
        Import-Module ToolFoundations
    }

    It 'Compare-Object:  compares differing sets.' {
        $result = Compare-Object 1,2,3 1,2,3,4

        $result | Should not beNullOrEmpty
        $result.InputObject   | Should be 4
        $result.SideIndicator | Should be '=>'
    }
    It 'Compare-Object2: compares differing sets.' {
        $result = Compare-Object2 1,2,3 1,2,3,4

        $result | Should not beNullOrEmpty
        $result.InputObject   | Should be 4
        $result.SideIndicator | Should be '=>'
    }
    It 'Compare-Object:  compares identical sets.' {
        $result = Compare-Object 1,2,3 1,2,3

        $result | Should beNullOrEmpty
    }
    It 'Compare-Object2: compares identical sets.' {
        $result = Compare-Object2 1,2,3 1,2,3

        $result | Should beNullOrEmpty
    }
    It 'Compare-Object:  throws an exception for a null ReferenceObject.' {
        { $result = Compare-Object $null 1,2,3 } | Should throw
    }
    It 'Compare-Object2: treats a Null ReferenceObject like an empty list.' {
        $result = Compare-Object2 $null 1,2,3

        $result | Should not beNullOrEmpty
        $result.Count            | Should be 3
        $result[0].InputObject   | Should be 1
        $result[0].SideIndicator | Should be '=>'
        $result[1].InputObject   | Should be 2
        $result[1].SideIndicator | Should be '=>'
        $result[2].InputObject   | Should be 3
        $result[2].SideIndicator | Should be '=>'
    }
    It 'Compare-Object:  throws an exception for a null DifferenceObject.' {
        { $result = Compare-Object 1,2,3 $null } | Should throw
    }
    It 'Compare-Object2: treats a Null DifferenceObject like an empty list.' {
        $result = Compare-Object2 1,2,3 $null

        $result | Should not beNullOrEmpty
        $result.Count            | Should be 3
        $result[0].InputObject   | Should be 1
        $result[0].SideIndicator | Should be '<='
        $result[1].InputObject   | Should be 2
        $result[1].SideIndicator | Should be '<='
        $result[2].InputObject   | Should be 3
        $result[2].SideIndicator | Should be '<='
    }
    It 'Compare-Object:  throws an exception for two null parameters.' {
        { $result = Compare-Object $null $null } | Should throw
    }
    It 'Compare-Object2: treats two Null parameters as matching.' {
        $result = Compare-Object2 $null $null

        $result | Should beNullOrEmpty
    }
    It 'Compare-Object:  false ReferenceObject.' {
        $result = Compare-Object $false 1,2,3

        $result | Should not beNullOrEmpty
        $result.Count            | Should be 4
        $result[0].InputObject   | Should be 1
        $result[0].SideIndicator | Should be '=>'
        $result[1].InputObject   | Should be 2
        $result[1].SideIndicator | Should be '=>'
        $result[2].InputObject   | Should be 3
        $result[2].SideIndicator | Should be '=>'
        $result[3].InputObject   | Should be $false
        $result[3].SideIndicator | Should be '<='
    }
    It 'Compare-Object2: same behavior for false ReferenceObject.' {
        $result = Compare-Object2 $false 1,2,3

        $result | Should not beNullOrEmpty
        $result.Count            | Should be 4
        $result[0].InputObject   | Should be 1
        $result[0].SideIndicator | Should be '=>'
        $result[1].InputObject   | Should be 2
        $result[1].SideIndicator | Should be '=>'
        $result[2].InputObject   | Should be 3
        $result[2].SideIndicator | Should be '=>'
        $result[3].InputObject   | Should be $false
        $result[3].SideIndicator | Should be '<='
    }
    It 'Compare-Object:  false DifferenceObject.' {
        $result = Compare-Object 1,2,3 $false

        $result | Should not beNullOrEmpty
        $result.Count            | Should be 4
        $result[0].InputObject   | Should be $false
        $result[0].SideIndicator | Should be '=>'
        $result[1].InputObject   | Should be 1
        $result[1].SideIndicator | Should be '<='
        $result[2].InputObject   | Should be 2
        $result[2].SideIndicator | Should be '<='
        $result[3].InputObject   | Should be 3
        $result[3].SideIndicator | Should be '<='
    }
    It 'Compare-Object2: same behavior for false DifferenceObject.' {
        $result = Compare-Object2 1,2,3 $false

        $result | Should not beNullOrEmpty
        $result.Count            | Should be 4
        $result[0].InputObject   | Should be $false
        $result[0].SideIndicator | Should be '=>'
        $result[1].InputObject   | Should be 1
        $result[1].SideIndicator | Should be '<='
        $result[2].InputObject   | Should be 2
        $result[2].SideIndicator | Should be '<='
        $result[3].InputObject   | Should be 3
        $result[3].SideIndicator | Should be '<='
    }
    It 'Compare-Object:  linearizes the array of resulting diff objects.' {
        $result = @(1,2,3),@(1,2,3,4),@(1,2,3,4,5) | Compare-Object 1,2,3,4 -PassThru

        $result.Count    | Should be 8
    }
    It 'Compare-Object2: produces array of arrays that differ.' {
        $result = @(1,2,3),@(1,2,3,4),@(1,2,3,4,5) | Compare-Object2 1,2,3,4 -PassThru

        $result.Count    | Should be 2
        $result[0].Count | Should be 3
        $result[1].Count | Should be 5
    }
    It 'Compare-Object2: correctly passes through null DifferenceObject.' {
        $result = Compare-Object2 -ReferenceObject 1,2,3,4 -DifferenceObject $null -PassThru

        $result.Count | Should be 1
        $result[0]    | Should be $null
    }
    It 'Compare-Object2: correctly passes through null in array of DifferenceObjects.' {
        $result = @(1,2,3),$null,@(1,2,3,4),@(1,2,3,4,5) | Compare-Object2 1,2,3,4 -PassThru

        $result.Count | Should be 3
        $result[1]    | Should be $null
    }
    It 'Compare-Object2: correctly passes through object when compared to null.' {
        $result = ,@(1,2,3) | Compare-Object2 $null -PassThru

        $result.Count    | Should be 1
        $result[0].Count | Should be 3
    }
    It 'Compare-Object2: correctly passes through list items when compared to null.' {
        $result = @(1,2,3),$null,@(1,2,3,4),@(1,2,3,4,5) | Compare-Object2 $null -PassThru

        $result.Count    | Should be 3
        $result[1].Count | Should be 4
    }
}
