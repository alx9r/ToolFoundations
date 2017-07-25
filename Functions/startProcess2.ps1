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
        $RunAs,

        [switch]
        $TestDelay,

        [switch]
        $SetWorkingDirectory
    )
    process
    {
        # https://stackoverflow.com/a/11549817/1404637
        # https://stackoverflow.com/a/139604/1404637
        # https://stackoverflow.com/a/24371479/1404637
        # https://stackoverflow.com/a/7608823/1404637
        # http://alabaxblog.info/2013/06/redirectstandardoutput-beginoutputreadline-pattern-broken/
        # http://newsqlblog.com/2012/05/22/concurrency-in-powershell-multi-threading-with-runspaces/
        # http://www.codeproject.com/Tips/895840/Multi-Threaded-PowerShell-Cookbook

        # create process objects
        $psi = New-object System.Diagnostics.ProcessStartInfo
        $psi.CreateNoWindow = $true
        $psi.UseShellExecute = $false
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.FileName = $Command
        if ($Runas ) {$psi.Verb = 'RunAs'}
        if ($SetWorkingDirectory ) { $psi.WorkingDirectory = Get-Location | % { $_.Path } }
        $psi.Arguments = $Arguments
        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $psi

        # create the runspace pool
        $pool = [RunspaceFactory]::CreateRunspacePool(1,3)
        $pool.ApartmentState = 'STA'
        $pool.Open() | Out-Null

        # create the pipelines
        $stdOutPipeline =[powershell]::Create()
        $stdErrPipeline =[powershell]::Create()
        $stdOutPipeline.RunspacePool = $pool
        $stdErrPipeline.RunspacePool = $pool

        # add the tasks to the pipelines
        $stdOutTask = $stdOutPipeline.AddScript('$args[0].StandardOutput.ReadToEnd()').AddArgument($process)
        $stdErrTask = $stdErrPipeline.AddScript('$args[0].StandardError.ReadToEnd()').AddArgument($process)

        # start the process
        $process.Start() | Out-Null

        # use this to test for race conditions that could cause missing
        # lines at the beginning of the stdout and stderr streams
        if ( $TestDelay )
        {
            sleep -Seconds 2
        }

        # invoke the tasks
        $stdOutTaskHandle = $stdOutTask.BeginInvoke()
        $stdErrTaskHandle = $stdErrTask.BeginInvoke()

        # wait for the tasks
        if ( $PSVersionTable.PSVersion.Major -gt 2 )
        {
            $stdOutResult = $stdOutPipeline.EndInvoke($stdOutTaskHandle)
            $stdErrResult = $stdErrPipeline.EndInvoke($stdErrTaskHandle)
        }
        else
        {
            $stdOutResult = $stdOutPipeline.EndInvoke($stdOutTaskHandle)[0]
            $stdErrResult = $stdErrPipeline.EndInvoke($stdErrTaskHandle)[0]
        }

        # clean up
        $stdOutPipeline.Dispose() | Out-Null
        $stdErrPipeline.Dispose() | Out-Null
        $pool.Close() | Out-Null
        [GC]::Collect() | Out-Null

        # wait for the process to finish
        $process.WaitForExit() | Out-Null

        New-Object PSObject -Property @{
            StandardOutput = $stdOutResult
            StandardError  = $stdErrResult
            ExitCode       = $process.ExitCode
            ProcessObject  = $process
        }
    }
}

