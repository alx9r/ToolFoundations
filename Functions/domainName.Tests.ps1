Import-Module ToolFoundations -Force

InModuleScope ToolFoundations {
    Describe Test-ValidDomainName {
        It 'returns true for good domain names.' {
            'asdf.jk'  | Test-ValidDomainName | Should be $true
            'AsDf.Jk'  | Test-ValidDomainName | Should be $true
            'asdf.jkl' | Test-ValidDomainName | Should be $true
            'asd1.jkl' | Test-ValidDomainName | Should be $true
            'as-d.jkl' | Test-ValidDomainName | Should be $true
            'asdf.qwer.jkl' | Test-ValidDomainName | Should be $true
        }
        Context 'false' {
            Mock Write-Error
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
        It 'throws correct exception' {
            try
            {
                'asdf' | Test-ValidDomainName -ErrorAction Stop
            }
            catch [System.ArgumentException]
            {
                $threw = $true
                $_.Exception.Message | Should match 'asdf is not a valid domain name.'
                $_.Exception.ParamName | Should be DomainName
            }
            $threw | Should be $true
        }
    }
}
