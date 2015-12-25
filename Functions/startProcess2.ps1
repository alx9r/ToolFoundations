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
        [void]$process.Start()
        $process.WaitForExit()
        New-Object PSObject -Property @{
            StandardOutput = $process.StandardOutput.ReadToEnd()
            StandardError  = $process.StandardError.ReadToEnd()
            ExitCode       = $process.ExitCode
            ProcessObject  = $process
        }
    }
}

