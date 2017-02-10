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

    if ( $PSVersionTable.PSVersion.Major -ge 5 )
    {

    Describe Invoke-TcpRequest {
        Context 'success' {
            Mock Connect-Tcp -Verifiable {
                [System.Net.Sockets.TcpClient]::new()
            }
            Mock Invoke-TcpReadWrite -Verifiable {
                if ( $PSCmdlet.ParameterSetName -eq 'write' )
                {
                    return
                }
                'read value'
            }
            It 'returns read value' {
                $splat = @{
                    Encoding = [System.Text.Encoding]::ASCII
                    WriteString = 'write value'
                    IpAddress = '192.168.0.1'
                    Port = 23
                    Timeout = [timespan]::FromSeconds(1)
                }
                $r = Invoke-TcpRequest @splat
                $r | Should be 'read value'
            }
            It 'connects' {
                Assert-MockCalled Connect-Tcp 1 {
                    $IpAddress -eq '192.168.0.1' -and
                    $Port -eq '23' -and
                    $Timeout.TotalSeconds -eq 1
                }
            }
            It 'writes' {
                Assert-MockCalled Invoke-TcpReadWrite 1 {
                    $Encoding -eq [System.Text.Encoding]::ASCII -and
                    $WriteString -eq 'write value' -and
                    $TimeOut.TotalSeconds -eq 1
                }
            }
            It 'reads' {
                Assert-MockCalled Invoke-TcpReadWrite 1 {
                    $Encoding -eq [System.Text.Encoding]::ASCII -and
                    $null -eq $WriteString -and
                    $TimeOut.TotalSeconds -eq 1
                }
            }
        }
    }

    }
}
