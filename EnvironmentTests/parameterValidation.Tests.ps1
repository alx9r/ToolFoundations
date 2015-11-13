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
        if ($PSVersionTable.PSVersion.Major -le 4)
        {
            It 'does not throw exception on PowerShell 4 and earlier.' {
                $ErrorActionPreference = 'Continue'
                {@{x=1} | >> | f} | Should not throw
            }
        }
        else
        {
            It 'throws exception on PowerShell 5 and later.' {
                $ErrorActionPreference = 'Continue'
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
        It "throws when ErrorActionPreference eq 'Stop'" {
            $ErrorActionPreference = 'Stop'
            try
            {
                @{x=1} | >> | f
            }
            catch [System.Exception]
            {
                $threw = $true
                $_ | Should match "Cannot validate argument on parameter 'x'"
                $_.Exception -is [System.Management.Automation.ParameterBindingException] | Should be $true

            }
            $threw | Should be $true
        }
    }
}
