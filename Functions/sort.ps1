
# Sort- isn't an "approved verb" https://stackoverflow.com/q/27173621/1404637
Set-Alias Sort-Hashtables ConvertTo-SortedHashtables
Function ConvertTo-SortedHashtables
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory                       = $true,
                   ValueFromPipeline               = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [hashtable[]]
        $InputObject,

        [parameter(Position                        = 1,
                   Mandatory                       = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [Object[]]
        $Keys,

        [parameter(ValueFromPipelineByPropertyName = $true)]
        [switch]
        $Descending=$false
    )
    process
    {
        $InputObject |
            %{
                $h = @{
                    OriginalHash = $_
                }
                foreach ($key in $Keys)
                {
                    $h.$key = $_.$key
                }
                New-Object PSObject -Property $h
            } |
            Sort-Object $Keys -Descending:$Descending |
            % {$_.OriginalHash}
    }
}
