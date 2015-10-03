Describe Test-ValidDomainName {
    BeforeEach {
        Remove-Module ToolFoundations -ea SilentlyContinue
        Import-Module ToolFoundations
    }

    It 'returns true for good domain names.' {
        'asdf.jk'  | Test-ValidDomainName | Should be $true
        'AsDf.Jk'  | Test-ValidDomainName | Should be $true
        'asdf.jkl' | Test-ValidDomainName | Should be $true
        'asd1.jkl' | Test-ValidDomainName | Should be $true
        'as-d.jkl' | Test-ValidDomainName | Should be $true
        'asdf.qwer.jkl' | Test-ValidDomainName | Should be $true
    }
    It 'returns false for bad domain names.' {
        'asdf'     | Test-ValidDomainName | Should be $false
        'asdf.j'   | Test-ValidDomainName | Should be $false
        'asdf.as1' | Test-ValidDomainName | Should be $false
        '-asd.jkl' | Test-ValidDomainName | Should be $false
        'asd-.jkl' | Test-ValidDomainName | Should be $false
        'as_d.jkl' | Test-ValidDomainName | Should be $false
        'asdf.qw_r.jkl' | Test-ValidDomainName | Should be $false
        [string]::Empty | Test-ValidDomainName | Should be $false
    }
    It 'correctly bounds label lengths.' {
        '012345678901234567890123456789012345678901234567890123456789012.jkl' |
            Test-ValidDomainName | Should be $true
        '0123456789012345678901234567890123456789012345678901234567890123.jkl' |
            Test-ValidDomainName | Should be $false
    }
    It 'correctly bounds overall length.' {
        '012345678901234567890123456789012345678901234567890123456789.012345678901234567890123456789012345678901234567890123456789.012345678901234567890123456789012345678901234567890123456789.012345678901234567890123456789012345678901234567890123456789.012.abcde' |
            Test-ValidDomainName | Should be $true
'012345678901234567890123456789012345678901234567890123456789.012345678901234567890123456789012345678901234567890123456789.012345678901234567890123456789012345678901234567890123456789.012345678901234567890123456789012345678901234567890123456789.012.abcdef' |
            Test-ValidDomainName | Should be $false
    }
}
