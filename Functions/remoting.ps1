function Test-RemotingConnection
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position                        = 1,
                   Mandatory                       = $true,
                   ValueFromPipeline               = $true,
                   ValueFromPipelineByPropertyName = $true)]
        $ComputerName,

        [parameter(ValueFromPipelineByPropertyName = $true)]
        [System.Management.Automation.PSCredential]
        $Credential,

        # The FailAction passed to Publish-Failure when a test fails.
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [string]
        [ValidateSet('Error','Verbose','Throw')]
        [Alias('fa')]
        $FailAction='Verbose'
    )
    process
    {
        $bp = &(gbpm)
        $bp.Remove('FailAction')

        # based on http://www.leeholmes.com/blog/2009/11/20/testing-for-powershell-remoting-test-psremoting/
        try
        {
            $ErrorActionPreference = "Stop"
            $result = Invoke-Command {1} @bp
        }
        catch
        {
            &(Publish-Failure  "Test of Invoke-Command on computer $ComputerName failed." ([System.Runtime.Remoting.RemotingException]) $FailAction)
            return $false
        }

        ## I’ve never seen this happen, but if you want to be
        ## thorough….
        if($result -ne 1)
        {
            &(Publish-Failure "Remoting to $ComputerName returned an unexpected result." ([System.Runtime.Remoting.RemotingException]) $FailAction)
            return $false
        }

        return $true
    }
}
