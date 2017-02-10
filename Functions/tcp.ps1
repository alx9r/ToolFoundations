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
        # create the socket
        $socket = [System.Net.Sockets.TcpClient]::new()

        # begin connecting
        $handle = $socket.BeginConnect($IpAddress,$Port,$null,$null)

        # wait for connect to complete (or fail)
        $success = $handle.AsyncWaitHandle.WaitOne($TimeOut)

        if ( -not $success )
        {
            # we have timed out
            throw [System.TimeoutException]::new(
                "Timed out making TCP connection to $IpAddress`:$Port after $($TimeOut.TotalSeconds)s"
            )
        }

        # the socket has signaled that connect has ended

        try
        {
            # this will throw an exception if the connection was actively refused
            $socket.EndConnect($handle)
        }
        catch
        {
            # this is the last opportunity to clean up
            $socket.Close()
            $socket.Dispose()

            # re-throw the exception
            throw
        }

        # return the connected socket
        # it is the caller's responsibility to close and dispose
        return $socket
    }
}

function Invoke-TcpReadWrite
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true,
                   ValueFromPipeline = $true)]
        [System.Net.Sockets.TcpClient]
        $Socket,

        [Parameter(Mandatory = $true,
                   Position = 1)]
        [System.Text.Encoding]
        $Encoding,

        [Parameter(ParameterSetName = 'write',
                   Position = 2)]
        [string]
        $WriteString,

        [ValidateScript({$_ -gt 0})]
        [timespan]
        $TimeOut
    )
    process
    {
        # determine the mode
        switch ( $PSCmdlet.ParameterSetName )
        {
            'write'   { $mode = 'write' }
            default { $mode = 'read' }
        }

        # set up the stream type
        $socketType = @{
            write = [System.IO.StreamWriter]
            read  = [System.IO.StreamReader]
        }.$mode

        # set up to begin the task
        $beginTask = @{
            write = {
                $stream.AutoFlush = $true
                $stream.WriteAsync($WriteString)
            }
            read  = { $stream.ReadLineAsync() }
        }.$mode

        # create the stream
        $stream = $socketType::new($Socket.GetStream(),$Encoding)

        # start the task
        $task = & $beginTask

        # wait on the read
        $success = $task.Wait($TimeOut)

        if ( -not $success )
        {
            # we have timed out
            throw [System.TimeoutException]::new(
                "Timed out $mode`ing TCP connection $($Socket.Client.RemoteEndPoint.Address.IPAddressToString):$($Socket.Client.RemoteEndPoint.Port) after $($TimeOut.TotalSeconds)s"
            )
        }

        # the stream has signaled that the task has ended

        if ( $mode -eq 'read' )
        {
            return $task.Result
        }
    }
}

function Invoke-TcpRequest
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({$_ | Test-ValidIpAddress})]
        $IpAddress,

        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({$_ | Test-ValidTcpPort})]
        [int]
        $Port,

        [Parameter(Mandatory = $true,
                   Position = 1)]
        [System.Text.Encoding]
        $Encoding,

        [Parameter(Mandatory = $true,
                   Position = 2)]
        [string]
        $WriteString,

        [ValidateScript({$_ -gt 0})]
        [timespan]
        $Timeout
    )
    process
    {
        try
        {
            # connect
            $socket = Connect-Tcp $IpAddress $Port -TimeOut $Timeout

            # write
            $socket | Invoke-TcpReadWrite $Encoding $WriteString -TimeOut $Timeout

            # read
            return $socket | Invoke-TcpReadWrite $Encoding -TimeOut $Timeout
        }
        finally
        {
            # clean up the socket
            if ( $null -ne $socket )
            {
                $socket.Close()
                $socket.Dispose()
            }
        }
    }
}