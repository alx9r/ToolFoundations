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
