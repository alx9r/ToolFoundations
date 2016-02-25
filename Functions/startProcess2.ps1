function Start-Process2
{
    [CmdletBinding()]
    param
    (
        [string]
        $Command,

        [string[]]
        $Arguments,

        [switch]
        $RunAs
    )
    process
    {
        # https://stackoverflow.com/a/11549817/1404637
        # https://stackoverflow.com/a/139604/1404637
        # https://stackoverflow.com/a/24371479/1404637
        # https://stackoverflow.com/a/7608823/1404637

        # create process objects
        $psi = New-object System.Diagnostics.ProcessStartInfo
        $psi.CreateNoWindow = $true
        $psi.UseShellExecute = $false
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.FileName = $Command
        if ($Runas ) {$psi.Verb = 'RunAs'}
        $psi.Arguments = $Arguments
        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $psi

        # create string builders to store stdout and stderr.
        $stdOutBuilder = New-Object -TypeName System.Text.StringBuilder
        $stdErrBuilder = New-Object -TypeName System.Text.StringBuilder

        # create wait objects
        $stdOutWaitHandle = New-Object System.Threading.AutoResetEvent($false)
        $stdErrWaitHandle  = New-Object System.Threading.AutoResetEvent($false)

        # Add event handlers for stdout and stderr.
        $scriptBlock = {
            if ( -not [String]::IsNullOrEmpty($EventArgs.Data)) 
            {
                $Event.MessageData.StringBuilder.AppendLine($EventArgs.Data)
            }
            else
            {
                $Event.MessageData.WaitHandle.Set()
            }
        }
        $stdOutEvent = Register-ObjectEvent -InputObject $process `
            -Action $scriptBlock -EventName 'OutputDataReceived' `
            -MessageData @{ 
                StringBuilder = $stdOutBuilder
                WaitHandle    = $stdOutWaitHandle
            }
        $stdErrEvent = Register-ObjectEvent -InputObject $process `
            -Action $scriptBlock -EventName 'ErrorDataReceived' `
            -MessageData @{
                StringBuilder = $stdErrBuilder
                WaitHandle    = $stdErrWaitHandle
            }

        # start process.
        [Void]$process.Start()
        $process.BeginOutputReadLine()
        $process.BeginErrorReadLine()
        
        # wait for everything to finish
        if 
        (
            $process.WaitForExit() -and
            $stdOutWaitHandle.WaitOne() -and
            $stdErrWaitHandle.WaitOne()
        )
        {
            # process completed 
        }
        else
        {
            # timed out
        }

        # Unregistering events to retrieve process output.
        Unregister-Event -SourceIdentifier $stdOutEvent.Name
        Unregister-Event -SourceIdentifier $stdErrEvent.Name

        New-Object PSObject -Property @{
            StandardOutput = $stdOutBuilder.ToString()
            StandardError  = $stdErrBuilder.ToString()
            ExitCode       = $process.ExitCode
            ProcessObject  = $process
        }
    }
}

