Import-Module ToolFoundations -Force

Describe 'ValidateScript' {
    Context 'fails validation' {
        function f
        {
            [CmdletBinding()]
            param
            (
                [ValidateScript({$false})]
                $x
            )
            process{}
        }
        It 'throws correct exception.' {
            try
            {
                f -x 1
            }
            catch [System.Management.Automation.ParameterBindingException]
            {
                $threw = $true
                $_ | Should match "Cannot validate argument on parameter 'x'"
            }
            $threw | Should be $true
        }
    }
    Context 'pipeline' {
        function f
        {
            [CmdletBinding()]
            param
            (
                [parameter(ValueFromPipelineByPropertyName = $true)]
                [ValidateScript({$false})]
                $x
            )
            process{}
        }
        It 'does not throw exception.' {
            {@{x=1} | >> | f} | Should not throw
        }
        It "throws when ErrorActionPreference eq 'Stop'" {
            $ErrorActionPreference = 'Stop'
            try
            {
                @{x=1} | >> | f
            }
            catch [System.Management.Automation.ParameterBindingException]
            {
                $threw = $true
                $_ | Should match "Cannot validate argument on parameter 'x'"
            }
            $threw | Should be $true
        }
    }
}
