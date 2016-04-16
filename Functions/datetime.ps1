function Get-ThisMonthsPatchTuesday
{
    [CmdletBinding()]
    [OutputType([datetime])]
    param
    (
        [Parameter(Position = 1,
                   ValueFromPipeline = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [DateTime]
        $DateTime = (Get-Date)
    )
    process
    {
        $splat = @{
            Day = 8
            Hour = 0
            Minute = 0
            Second = 0
        }
        $thisMonthsPT = Get-Date $DateTime @splat
        $thisMonthsPT = $thisMonthsPT.AddMilliseconds(-$thisMonthsPT.Millisecond)
        while ($thisMonthsPT.DayOfWeek -ne [System.DayOfWeek]::Tuesday)
        {
            $thisMonthsPT = $thisMonthsPT.AddDays(1)
        }
        return $thisMonthsPT
    }
}
function Get-LastPatchTuesday
{
    [CmdletBinding()]
    [OutputType([datetime])]
    param
    (
        [Parameter(Position = 1,
                   ValueFromPipeline = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [DateTime]
        $DateTime = (Get-Date)
    )
    process
    {
        $splat = @{
            Hour = 0
            Minute = 0
            Second = 0
        }
        $DateTime = Get-Date $DateTime @splat
        $DateTime = $DateTime.AddMilliseconds(-$DateTime.Millisecond)

        if ( $DateTime -ge ($DateTime | Get-ThisMonthsPatchTuesday) )
        {
            return $DateTime | Get-ThisMonthsPatchTuesday
        }

        return $DateTime.AddMonths(-1) | Get-ThisMonthsPatchTuesday
    }
}
function Get-NextPatchTuesday
{
    [CmdletBinding()]
    [OutputType([datetime])]
    param
    (
        [Parameter(Position = 1,
                   ValueFromPipeline = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [DateTime]
        $DateTime = (Get-Date)
    )
    process
    {
        $splat = @{
            Hour = 0
            Minute = 0
            Second = 0
        }
        $DateTime = Get-Date $DateTime @splat
        $DateTime = $DateTime.AddMilliseconds(-$DateTime.Millisecond)

        if ( $DateTime -lt ($DateTime | Get-ThisMonthsPatchTuesday) )
        {
            return $DateTime | Get-ThisMonthsPatchTuesday
        }

        return $DateTime.AddMonths(1) | Get-ThisMonthsPatchTuesday
    }
}
