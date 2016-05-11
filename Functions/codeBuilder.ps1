function ConvertTo-PsLiteralString
{
<#
.SYNOPSIS
Converts an object to powershell string literal.

.DESCRIPTION
ConvertTo-PsLiteralString converts an object to a literal representation of the object.  This is useful when the contents of an in-memory object needs to be deferred for future execution by another part of the script or another computer.

ConvertTO-PSLiteralString supports strings, arrays, and hashtables and nestings thereof.

.OUTPUTS
A string literal representing the contents of Object.

Throws NotSupportedException when an object of an unsupported type is encountered.

.EXAMPLE
    ConvertTo-PsLiteralString 'asdf','jkl'
@(
    'asdf',
    'jkl'
)

.EXAMPLE
    ConvertTo-PsLiteralString @{ foo='bar' }
@{
    foo='bar'
}

.EXAMPLE
    ConvertTo-PsLiteralString @(@{a = 'b';c ='d'},@('asdf','asdf',@{foo='bar'}))
@(
    @{
        a='b'
        c='d'
    },
    @(
        'asdf',
        'asdf',
        @{
            foo='bar'
        }
    )
)

ConvertTo-PsLiteralString recursively traverses object trees to compose the full literal string.

.EXAMPLE
    ConvertTo-PsLiteralString @(@{a = 'b';c ='d'},@('asdf','asdf',@{foo='bar'})) -Depth 1
@(
        @{
            a='b'
            c='d'
        },
        @(
            'asdf',
            'asdf',
            @{
                foo='bar'
            }
        )
    )

Use Depth to add levels of indentation to the literal string. The first line is unaffected because the first line will generally need to follow code on an existing line.
#>
    param
    (
        # the object to traverse
        [parameter(Mandatory                       = $true,
                   Position                        = 1,
                   ValueFromPipeline               = $true,
                   ValueFromPipelineByPropertyName = $true)]
        $Object,

        # the number of tab positions to indent the output literal string
        [parameter(Position                        = 2,
                   ValueFromPipelineByPropertyName = $true)]
        [uint32]
        $Depth=0,

        # the newline character to use
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [string]
        $NewLine=@'


'@,

        # Tabs vs spaces? I don't care. Neither does ConvertTo-PsLiteralString.  Just pass the indentation character(s) to which you happen pledge holy allegiance to Tab.  You can even use IndentationCharacters instead of Tab if you prefer to express your non-denominationalism.
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [Alias('IndentationCharacters')]
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
        if ( $Object -is [int])
        {
            return "$Object"
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
        throw New-Object System.NotSupportedException(
            "Object $Object is of type $($Object.GetType()). Conversion for this type is not implemented.",
            'Object'
        )
    }
}
