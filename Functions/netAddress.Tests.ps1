Import-Module ToolFoundations -Force

InModuleScope ToolFoundations {
    Describe Test-ValidNetAddress {
        Context 'valid IP address' {
            Mock Test-ValidIpAddress -Verifiable { $true }
            Mock Test-ValidDomainName -Verifiable
            It 'returns true' {
                $r = 'valid ip address' | Test-ValidNetAddress
                $r | Should be $true
            }
            It 'invokes correct commands' {
                Assert-MockCalled Test-ValidIpAddress 1 {
                    $IpAddress -eq 'valid ip address'
                }
                Assert-MockCalled Test-ValidDomainName 0 -Exactly
            }
        }
        Context 'valid domain name' {
            Mock Test-ValidIpAddress -Verifiable { $false }
            Mock Test-ValidDomainName -Verifiable { $true }
            It 'returns true' {
                $r = 'valid domain name' | Test-ValidNetAddress
                $r | Should be $true
            }
            It 'invokes correct commands' {
                Assert-MockCalled Test-ValidIpAddress 1 {
                    $IpAddress -eq 'valid domain name'
                }
                Assert-MockCalled Test-ValidDomainName 1 {
                    $DomainName -eq 'valid domain name'
                }
            }
        }
        Context 'invalid address' {
            Mock Test-ValidIpAddress -Verifiable { $false }
            Mock Test-ValidDomainName -Verifiable { $false }
            It 'returns true' {
                $r = 'invalid address' | Test-ValidNetAddress
                $r | Should be $false
            }
            It 'invokes correct commands' {
                Assert-MockCalled Test-ValidIpAddress 1 {
                    $IpAddress -eq 'invalid address'
                }
                Assert-MockCalled Test-ValidDomainName 1 {
                    $DomainName -eq 'invalid address'
                }
            }
        }
        Context 'exception' {
            Mock Test-ValidIpAddress -Verifiable { $false }
            Mock Test-ValidDomainName -Verifiable { $false }
            It 'throws correct exception' {
                try
                {
                    'invalid address' | Test-ValidNetAddress -ErrorAction Stop
                }
                catch [System.ArgumentException]
                {
                    $threw = $true
                    $_.Exception.Message | Should match 'is not a valid'
                    $_.Exception.ParamName | Should be Address
                }
                $threw | Should be $true
            }
            It 'invokes correct commands' {
                Assert-MockCalled Test-ValidIpAddress 1 {
                    $IpAddress -eq 'invalid address'
                }
                Assert-MockCalled Test-ValidDomainName 1 {
                    $DomainName -eq 'invalid address'
                }
            }
        }
    }
}
