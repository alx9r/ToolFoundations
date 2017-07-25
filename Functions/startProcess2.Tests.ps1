Import-Module ToolFoundations -Force

$resourcePath = "$(Split-Path $MyInvocation.MyCommand.Path –Parent)\..\Resources" |
    Resolve-Path |
    % {$_.Path}

Describe Start-Process2 {
    Context 'stdout from more.com' {
        $morePath = Get-Command more.com | % {$_.Path}

        $sizes = '1k','10k'#,'100k'
        foreach ( $size in $sizes)
        {
            It "correctly handles $size lines" {
                $txtPath = "$resourcePath\linesX$size.txt"
                $text = Get-RawContent $txtPath

                $result = Start-Process2 -Command $morePath -Arguments $txtPath

                $result.ExitCode | Should be 0
                $result.StandardOutput.Length | Should be $text.Length
                $result.StandardOutput | Should be $text
            }
        }
    }
    Context 'stdout from powershell.exe' {
        $psPath = Get-Command powershell.exe | % {$_.Path}

        $sizes = '1k','10k'#,'100k'
        foreach ( $size in $sizes)
        {
            It "correctly handles $size lines" {
                $txtPath = "$resourcePath\linesX$size.txt"
                $text = Get-RawContent $txtPath

                $result = Start-Process2 -Command $psPath -Arguments "-Command Get-Content $txtPath"

                $result.ExitCode | Should be 0
                $result.StandardOutput.Length | Should be $text.Length
                $result.StandardOutput | Should be $text
            }
        }
    }
    Context 'TestDelay' {
        $morePath = Get-Command more.com | % {$_.Path}

        It 'correctly handles test delay' {
            $txtPath = "$resourcePath\linesX1k.txt"
            $text = Get-RawContent $txtPath

            $result = Start-Process2 -Command $morePath -Arguments $txtPath -TestDelay

            $result.ExitCode | Should be 0
            $result.StandardOutput.Length | Should be $text.Length
            $result.StandardOutput | Should be $text
        }
    }
    Context 'Exit Codes' {
        It 'correctly outputs exit code.' {
            $splat = @{
                Command = Get-Command powershell.exe | % {$_.Path}
                Arguments = '-Command [System.Environment]::Exit(999)'
            }
            $result = Start-Process2 @splat

            $result.ExitCode | Should be 999
        }
    }
    Context 'stderr' {
        It 'correctly outputs stderr' {
            $splat = @{
                Command = Get-Command powershell.exe | % {$_.Path}
                Arguments = "-Command `$host.ui.WriteErrorLine('my error')"
            }
            $result = Start-Process2 @splat

            $result.StandardError | Should be "my error`r`n"
        }
    }
    Context 'set working directory' {
        $stashLocation = Get-Location
        It 'switch to working location' {
            Set-Location $resourcePath
        }
        It 'uses the current location as the working directory' {
            $r = Start-Process2 powershell.exe '-command "Get-Location | % {$_.Path}"' -SetWorkingDirectory

            $r.ExitCode | Should be 0
            $r.StandardOutput | Should be "$resourcePath`r`n"
        }
        It 'switch to stashed location' {
            $stashLocation | Set-Location
        }
    }
}
