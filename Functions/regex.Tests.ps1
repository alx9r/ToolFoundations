Describe Test-ValidRegex {
    BeforeEach {
        Remove-Module ToolFoundations -ea SilentlyContinue
        Import-Module ToolFoundations
    }

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
    BeforeEach {
        Remove-Module ToolFoundations -ea SilentlyContinue
        Import-Module ToolFoundations
    }

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
    It "correctly escapes a mixed characters." {
        $r = $SomeEscaping | ConvertTo-RegexEscapedString
        $r | Should be "Yup,\ just\ a\ bunch\ of\ `"normal`"\ characters!\ 'Cept\ white\ space\.\ \(and\ periods\.\.\.and\ parentheses\)"
    }
    It "correctly handles empty strings." {
        $r = [string]::Empty | ConvertTo-RegexEscapedString
        $r -eq [string]::Empty | Should be $true
    }
}
