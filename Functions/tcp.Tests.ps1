Import-Module ToolFoundations -Force

InModuleScope ToolFoundations {
    Describe Test-ValidTcpPort {
        Context 'returns false for bad port numbers' {
            foreach ( $portNumber in @(
                    -1
                    65536
                )
            )
            {
                It $portNumber {
                    $portNumber | Test-ValidTcpPort | Should be $false
                }
            }
        }
        Context 'returns true for good port numbers' {
            foreach ( $portNumber in @(
                    0
                    1
                    65535
                )
            )
            {
                It $portNumber {
                    $portNumber | Test-ValidTcpPort | Should be $true
                }
            }
        }
        It 'throws correct exception' {
            try
            {
                -1 | Test-ValidTcpPort -ErrorAction Stop
            }
            catch [System.ArgumentException]
            {
                $threw = $true
                $_.Exception.Message | Should match 'is not a valid'
                $_.Exception.ParamName | Should be PortNumber
            }
            $threw | Should be $true
        }
    }
}
