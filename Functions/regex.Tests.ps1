Import-Module ToolFoundations -Force
Describe Test-ValidRegex {
    #http://stackoverflow.com/q/7095238/1404637
    $bad  = '*','[0-9]++','['

    #http://regexlib.com/CheatSheet.aspx
    $good = '^abc','abc$','a.c','bill|ted','ab{2}c','a[bB]c','a[bB]c','(abc){2}','ab*c','ab+c','ab?c','a\sc'


    It 'returns false for invalid regex.' {
        $bad | Test-ValidRegex |
            % { $_ | Should be $false }
    }
    It 'returns false for empty pattern.' {
        Test-ValidRegex -Pattern ([string]::Empty) | Should be $false
    }
    It 'returns true for valid regex.' {
        $good | Test-ValidRegex |
            % { $_ | Should be $true }
    }
}
Describe ConvertTo-RegexEscapedString {
    # http://stackoverflow.com/a/12963199/1404637
    $NeedEscaping = '\t\n\f\r#$()*+.?[\^{|'
    $NoEscaping   = 'zxcvbnmasdfghjklqwertyuiop'
    $SomeEscaping   = "Yup, just a bunch of `"normal`" characters! 'Cept white space. (and periods...and parentheses)"
    It 'outputs correctly escaped regex metacharacters.' {
        $r = $NeedEscaping | ConvertTo-RegexEscapedString
        $r | Should be '\\t\\n\\f\\r\#\$\(\)\*\+\.\?\[\\\^\{\|'
    }
    It "doesn't escape non-metacharacters." {
        $r = $NoEscaping | ConvertTo-RegexEscapedString
        $r | Should be $NoEscaping
    }
    It 'correctly escapes a mixed characters.' {
        $r = $SomeEscaping | ConvertTo-RegexEscapedString
        $r | Should be "Yup,\ just\ a\ bunch\ of\ `"normal`"\ characters!\ 'Cept\ white\ space\.\ \(and\ periods\.\.\.and\ parentheses\)"
    }
    It 'correctly handles empty strings.' {
        $r = [string]::Empty | ConvertTo-RegexEscapedString
        $r -eq [string]::Empty | Should be $true
    }
}
Describe ConvertFrom-RegexNamedGroupCapture {
    Context 'failure' {
        It 'throws when there are no captures' {
            $regex = [regex]'a=(?<a>[0-9]*);b=(?<b>[0-9]*)'
            $match = $regex.Match('c=1;d=2')
            { ConvertFrom-RegexNamedGroupCapture -Match $match -Regex $regex} |
                Should throw 'Match does not contain any captures.'
        }
    }
    Context 'success' {
        $regex = [regex]'a=(?<a>[0-9]*);b=(?<b>[0-9]*)'
        $match = $regex.Match('a=1;b=2')
        $r = ConvertFrom-RegexNamedGroupCapture -Match $match -Regex $regex
        It 'outputs a hashtable.' {
            $r -is [hashtable] | Should be $true
        }
        It 'contains two keys.' {
            $r.Keys.Count | Should be 2
        }
        It 'a=1' {
            $r.a | Should be '1'
        }
        It 'b=2' {
            $r.b | Should be '2'
        }
    }
}
