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
        if ( ([string]$InputObject.GetType()) -eq 'System.Collections.Generic.Dictionary[string,System.Object]' )
        {
            $InputObject.Keys |
                % {
                    $h[$_] = $InputObject[$_]
                }
        }
        # default case
        else
        {
            $InputObject | gm | ? {'Property','NoteProperty' -contains $_.MemberType} |
                % {
                    $h[$_.Name] = $InputObject | Select-Object -ExpandProperty $_.Name
                }
        }

        if ($h.Keys.Count) {$h}
    }
}
