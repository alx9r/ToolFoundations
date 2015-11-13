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
}
