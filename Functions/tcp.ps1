function Test-ValidTcpPort
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory         = $true,
                   Position          = 1,
                   ValueFromPipeline = $true)]
        [int]
        $PortNumber
    )
    process
    {
        if
        (
            ($PortNumber -ge 0) -and 
            ($PortNumber -le 65535)
        )
        {
            return $true
        }
        
        &(Publish-Failure "$PortNumber is not a valid TCP port number",'PortNumber' ([System.ArgumentException]))

        return $false
    }
}

function Connect-Tcp
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateScript({$_ | Test-ValidIpAddress})]
        $IpAddress,

        [Parameter(Mandatory = $true)]
        [ValidateScript({$_ | Test-ValidTcpPort})]
        $Port,

        [ValidateScript({$_ -gt 0})]
        [timespan]
        $TimeOut
    )
    process
    {
    }
}

function Invoke-TcpRequest
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateScript({$_ | Test-ValidIpAddress})]
        $IpAddress,

        [Parameter(Mandatory = $true)]
        [ValidateScript({$_ | Test-ValidTcpPort})]
        $Port,

        [Parameter(Mandatory = $true)]
        [System.Text.Encoding]
        $Encoding,

        [ValidateScript({$_ -gt 0})]
        [int]
        $Timeoutms
    )
    process
    {
    }
}