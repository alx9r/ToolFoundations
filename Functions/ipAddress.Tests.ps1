Import-Module ToolFoundations -Force

InModuleScope ToolFoundations {
    Describe Test-ValidIpAddress {
        Context 'returns false for bad addresses' {
            foreach ( $address in @(
                    '.2.3.4'
                    '1.2.3.'
                    '1.2.3.256'
                    '1.2.256.4'
                    '1.256.3.4'
                    '256.2.3.4'
                    '1.2.3.4.5'
                    '1..3.4'
                )
            )
            {
                It $address {
                    $address | Test-ValidIpAddress | Should be $false
                }
            }
        }
        Context 'returns true for good addresses' {
            foreach ( $address in @(
                    # special but probably not publicly routable
                    '0.1.2.3'         # (0.0.0.0/8 is reserved for some broadcasts)
                    '10.1.2.3'        # (10.0.0.0/8 is considered private)
                    '172.16.1.2'      # (172.16.0.0/12 is considered private)
                    '172.31.1.2'      # (same as previous, but near the end of that range)
                    '192.168.1.2'     # (192.168.0.0/16 is considered private)
                    '255.255.255.255' # (reserved broadcast is not an IP)

                    # publicly routable
                    '1.0.1.0'         # (China)
                    '8.8.8.8'         # (Google DNS in USA)
                    '100.1.2.3'       # (USA)
                    '172.15.1.2'      # (USA)
                    '172.32.1.2'      # (USA)
                    '192.167.1.2'     # (Italy)
                )
            )
            {
                It $address {
                    $address | Test-ValidIpAddress | Should be $true
                }
            }
        }
        It 'throws correct exception' {
            try
            {
                '.2.3.4' | Test-ValidIpAddress -ErrorAction Stop
            }
            catch [System.ArgumentException]
            {
                $threw = $true
                $_.Exception.Message | Should match 'is not a valid'
                $_.Exception.ParamName | Should be IpAddress
            }
            $threw | Should be $true
        }
    }
}
