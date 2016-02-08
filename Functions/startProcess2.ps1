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

        # Creating string builders to store stdout and stderr.
        $stdOutBuilder = New-Object -TypeName System.Text.StringBuilder
        $stdErrBuilder = New-Object -TypeName System.Text.StringBuilder

        # Adding event handers for stdout and stderr.
        $scriptBlock = {
            if (! [String]::IsNullOrEmpty($EventArgs.Data)) {
                $Event.MessageData.AppendLine($EventArgs.Data)
            }
        }
        $stdOutEvent = Register-ObjectEvent -InputObject $process `
            -Action $scriptBlock -EventName 'OutputDataReceived' `
            -MessageData $stdOutBuilder
        $stdErrEvent = Register-ObjectEvent -InputObject $process `
            -Action $scriptBlock -EventName 'ErrorDataReceived' `
            -MessageData $stdErrBuilder

        # Starting process.
        [Void]$process.Start()
        $process.BeginOutputReadLine()
        $process.BeginErrorReadLine()
        [Void]$process.WaitForExit()

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

