Import-Module ToolFoundations -Force

Describe 'ConvertTo-PsLiteralString' {
    It 'correctly converts single string.' {
        $s = 'asdf'
        ConvertTo-PsLiteralString $s |
            Should be "'asdf'"
    }
    It 'correctly converts array of two strings.' {
        $s = 'asdf','jkl'
        $r = ConvertTo-PsLiteralString $s
        $r | Should be @'
@(
    'asdf',
    'jkl'
)
'@
    }
    It 'correctly converts array of four string.' {
        $s = 'asdf','jkl','asdf','jkl'
        ConvertTo-PsLiteralString $s |
            Should be @'
@(
    'asdf',
    'jkl',
    'asdf',
    'jkl'
)
'@
    }
    It 'correctly converts nested array of strings.' {
        $a = @('asdf','jkl',@('asdf','jkl'))
        $r = ConvertTo-PsLiteralString $a
        $r | Should be @'
@(
    'asdf',
    'jkl',
    @(
        'asdf',
        'jkl'
    )
)
'@
    }
    It 'correctly converts an integer.' {
        $i = 1
        $r = ConvertTo-PsLiteralString $i
        $r | Should be '1'
    }
    It 'correctly converts a negative integer.' {
        $i = -1000
        $r = ConvertTo-PsLiteralString $i
        $r | Should be '-1000'
    }
    It 'correctly converts a single-element hashtable.' {
        $h = @{ foo='bar' }
        ConvertTo-PsLiteralString $h |
            Should be @'
@{
    foo='bar'
}
'@
    }
    It 'correctly converts a two-element hashtable.' {
        $h = @{foo='bar';gar2='foo2'}
        ConvertTo-PsLiteralString $h |
            Should be @'
@{
    foo='bar'
    gar2='foo2'
}
'@
    }
    It 'correctly converts a mix of hashtables and arrays. (1)' {
        $m = @(
            @{a = 'b';c ='d'},
            @('asdf','asdf',@{foo='bar'})
        )
        ConvertTo-PsLiteralString $m |
            Should be @'
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
'@
    }
    It 'correctly converts a mix of hashtables and arrays. (2)' {
        $m = @{
                foo = 'asdf','asdf'
                bar = 'jkl;','jkl;','jkl;'
            }
        ConvertTo-PsLiteralString $m |
            Should be @'
@{
    bar=@(
        'jkl;',
        'jkl;',
        'jkl;'
    )
    foo=@(
        'asdf',
        'asdf'
    )
}
'@
    }
    It 'correctly changes the indentation depth.' {
        $m = @{
                foo = 'asdf','asdf'
                bar = 'jkl;','jkl;','jkl;'
            }
        $r = ConvertTo-PsLiteralString $m -Depth 1
        $r | Should be @'
@{
        bar=@(
            'jkl;',
            'jkl;',
            'jkl;'
        )
        foo=@(
            'asdf',
            'asdf'
        )
    }
'@
    }
    It 'correctly converts booleans' {
        $m = @{foo = $true,$false}
        $r = ConvertTo-PsLiteralString $m -Depth 1
        $r | Should be @'
@{
        foo=@(
            $true,
            $false
        )
    }
'@
    }
    It 'throws correct error for an unhandled type.' {
        try
        {
            ConvertTo-PsLiteralString (Get-Date)
        }
        catch [System.NotSupportedException]
        {
            $threw = $true
            $_.Exception.Message | Should Match 'datetime. Conversion for this type is not implemented.'
        }

        $threw | Should be $true
    }
}
