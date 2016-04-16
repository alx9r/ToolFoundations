Import-Module ToolFoundations -Force

Describe Get-ThisMonthsPatchTuesday {
    Context 'returns correct day' {
        $cases = @(
            # Input         Output
            @('2015-12-31', '2015-12-08'),
            @('2016-01-01', '2016-01-12'),
            @('2016-01-11', '2016-01-12'),
            @('2016-01-12', '2016-01-12'),
            @('2016-01-31', '2016-01-12'),
            @('2016-02-01', '2016-02-09')
        )
        foreach ($case in $cases) {
            $in = $case[0]
            $out = $case[1]
            It $in {
                $r = $in | Get-ThisMonthsPatchTuesday
                $r -eq $out | Should be $true
            }
        }
    }
}
Describe Get-LastPatchTuesday {
    Context 'returns correct day' {
        $cases = @(
            # Input         Output
            @('2015-12-31', '2015-12-08'),
            @('2016-01-01', '2015-12-08'),
            @('2016-01-11', '2015-12-08'),
            @('2016-01-12', '2016-01-12'),
            @('2016-01-31', '2016-01-12'),
            @('2016-02-01', '2016-01-12')
        )
        foreach ($case in $cases) {
            $in = $case[0]
            $out = $case[1]
            It $in {
                $r = $in | Get-LastPatchTuesday
                $r -eq $out | Should be $true
            }
        }
    }
}
Describe Get-NextPatchTuesday {
    Context 'returns correct day' {
        $cases = @(
            # Input         Output
            @('2015-12-31', '2016-01-12'),
            @('2016-01-01', '2016-01-12'),
            @('2016-01-11', '2016-01-12'),
            @('2016-01-12', '2016-02-09'),
            @('2016-01-31', '2016-02-09'),
            @('2016-02-01', '2016-02-09')
        )
        foreach ($case in $cases) {
            $in = $case[0]
            $out = $case[1]
            It $in {
                $r = $in | Get-NextPatchTuesday
                $r -eq $out | Should be $true
            }
        }
    }
}
