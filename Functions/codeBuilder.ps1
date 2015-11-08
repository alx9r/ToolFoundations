function ConvertTo-PsLiteralString
{
    param
    (
        [parameter(Mandatory                       = $true,
                   Position                        = 1,
                   ValueFromPipelineByPropertyName = $true)]
        $Object,

        [parameter(Position                        = 2,
                   ValueFromPipelineByPropertyName = $true)]
        [uint32]
        $Depth=0,

        [parameter(ValueFromPipelineByPropertyName = $true)]
        [string]
        $NewLine="`r`n",

        [parameter(ValueFromPipelineByPropertyName = $true)]
        [string]
        $Tab='    '
    )
    process
    {
        $nl = $NewLine
        $t  = $Tab
        $d  = $Depth

        if ( $Object -is [string] )
        {
            return "'$Object'"
        }
        if ( $Object -is [array] )
        {
            $acc = "@($nl"

            $q = [System.Collections.Queue]$Object

            while ( $q.Count )
            {
                $item = $q.Dequeue()
                $acc = "$acc$($t*($d+1))$(ConvertTo-PsLiteralString $item ($d+1))"
                if ( $q.Count )
                {
                    $acc="$acc,$nl"
                }
            }

            return "$acc$nl$($t*$d))"
        }
        if ( $Object -is [hashtable] )
        {
            $acc = "@{$nl"
            $q = [System.Collections.Queue]@($Object.Keys | Sort)

            while ( $q.Count )
            {
                $key = $q.Dequeue()
                $acc = "$acc$($t*($d+1))$key=$(ConvertTo-PsLiteralString $Object[$key] ($d+1))"
                if ( $q.Count )
                {
                    $acc="$acc$nl"
                }
            }
            return "$acc$nl$($t*$d)}"
        }
        throw New-Object System.ArgumentException(
            "Object $Object is of type $($Object.GetType()). Conversion for this type is not implemented.",
            'Object'
        )
    }
}
