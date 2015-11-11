Import-Module ToolFoundations -Force

InModuleScope ToolFoundations {
Describe Test-RemotingConnection {
    Context 'success' {
        Mock Invoke-Command -Verifiable {1}
        It 'returns true.' {
            $r = 'computername' | Test-RemotingConnection
            $r | Should be $true

            Assert-MockCalled Invoke-Command -Exactly -Times 1 {
                $ComputerName -eq 'computername' -and
                (Invoke-Command $ScriptBlock) -eq 1
            }
        }
    }
    Context 'fail' {
        Mock Invoke-Command -Verifiable { throw }
        It 'throws correct exception on Invoke-Command failure.' {
            try
            {
                'computername' | Test-RemotingConnection -FailAction Throw
            }
            catch [System.Runtime.Remoting.RemotingException]
            {
                $threw = $true
                $_.Exception.Message | Should match 'Test of Invoke-Command on computer computername failed.'
            }
            $threw | Should be $true
        }
    }
     Context 'fail' {
        Mock Invoke-Command -Verifiable { 2 }
        It 'throws correct exception on incorrect result.' {
            try
            {
                'computername' | Test-RemotingConnection -FailAction Throw
            }
            catch [System.Runtime.Remoting.RemotingException]
            {
                $threw = $true
                $_.Exception.Message | Should match 'Remoting to computername returned an unexpected result.'
            }
            $threw | Should be $true
        }
    }
}
}
