Function ConvertTo-Hashtable
{
    [CmdletBinding()]
    param
    (
        [parameter(ValueFromPipeline=$true,
                   Position=1,
                   Mandatory=$true)]
        $InputObject
    )
    process
    {
        $h=@{}
            
        # special case for PSBoundParametersDictionary
        if ( $InputObject -is [System.Collections.Generic.Dictionary`2[System.String,System.Object]] )
        {
            $InputObject.Keys |
                % {
                    $h[$_] = $InputObject[$_]
                }
        }
        # default case
        else
        {
            $InputObject | gm | ? {$_.MemberType -in 'Property','NoteProperty'} |
                % {
                    $h[$_.Name] = $InputObject | Select-Object -ExpandProperty $_.Name
                }
        }

        if ($h.Keys.Count) {$h}
    }
}