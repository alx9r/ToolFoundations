Import-Module ToolFoundations -Force

InModuleScope ToolFoundations {
if ($PSVersionTable.PSVersion.Major -ge 4)
{
Describe Assert-ValidIdemFileParams {
    It 'throws correct exception when CopyPath matches Path' {
        $splat = @{
            Mode = 'set'
            Path = @{
                DriveLetter = 'a'
                Segments = 'path'
            }
            ItemType = 'File'
            CopyPath = @{
                DriveLetter = 'a'
                Segments = 'path'
            }
        }
        try
        {
            Assert-ValidIdemFileParams @splat
        }
        catch [System.ArgumentException]
        {
            $threw = $true
            $_.Exception.Message | Should match ''
        }
        $threw | Should be $true
    }
    It 'throws correct exception on CopyPath and Directory' {
        $splat = @{
            Mode = 'set'
            Path = @{
                DriveLetter = 'a'
                Segments = 'path'
            }
            ItemType = 'Directory'
            CopyPath = @{
                DriveLetter = 'b'
                Segments = 'path'
            }
        }
        try
        {
            Assert-ValidIdemFileParams @splat
        }
        catch [System.NotImplementedException]
        {
            $threw = $true
            $_.Exception.Message | Should match 'Copying of directories is not yet implemented.'
        }
        $threw | Should be $true
    }
    It 'throws correct exception when FileContents is provided for a Directory.' {
        $splat = @{
            Mode = 'set'
            Path = @{
                DriveLetter = 'a'
                Segments = 'path'
            }
            ItemType = 'Directory'
            FileContents = 'contents'
        }
        try
        {
            Assert-ValidIdemFileParams @splat
        }
        catch [System.ArgumentException]
        {
            $threw = $true
            $_.Exception.Message | Should match 'FileContents provided for a directory.'
        }
        $threw | Should be $true
    }
    It 'throws correct exception when FileContents and CopyPath are provided.' {
        $splat = @{
            Mode = 'set'
            Path = @{
                DriveLetter = 'a'
                Segments = 'path'
            }
            ItemType = 'File'
            FileContents = 'contents'
        }
        try
        {
            Assert-ValidIdemFileParams @splat
        }
        catch [System.ArgumentException]
        {
            $threw = $true
            $_.Exception.Message | Should match 'Both CopyPath and FileContents were provided.'
        }
    }
}
Describe 'Process-IdemFile' {
    Context 'nothing at CopyPath' {
        Mock New-Item {}
        Mock Copy-Item {}
        Mock Test-FilePath -Verifiable {$PathHashtable.DriveLetter -ne 'b'}
        It 'throws correct exception when CopyPath does not exist.' {
            $splat = @{
                Path = @{
                    DriveLetter = 'a'
                    Segments = 'seg'
                }
                ItemType = 'File'
                CopyPath = @{
                    DriveLetter = 'b'
                    Segments = 'seg'
                }
            }

            try
            {
                Process-IdemFile Set @splat -ea Stop
            }
            catch [System.ArgumentException]
            {
                $threw = $true
                $_.Exception.Message | Should match 'CopyPath b:\\seg does not exist.'
            }
            $threw | should be $true

            Assert-MockCalled Test-FilePath -Times 1 {
                $PathHashtable.DriveLetter -eq 'b' -and
                $ItemType -eq 'File'
            }
        }
    }
}
Describe 'Process-IdemFile Set' {
    Context 'cannot set Path' {
        Mock New-Item {}
        Mock Copy-Item {}
        Mock Test-FilePath -Verifiable {$true}
        Mock Process-Idempotent -Verifiable {$false}
        It 'throws correct exception when Path cannot be set.' {
            $splat = @{
                Path = @{
                    DriveLetter = 'a'
                    Segments = 'seg.txt'
                }
                ItemType = 'File'
            }

            try
            {
                Process-IdemFile Set @splat -ea Stop
            }
            catch [System.IO.FileNotFoundException]
            {
                $threw = $true
                $_.Exception.Message | Should match 'Set failed for a:\\seg.txt.'
            }
            $threw | Should be $true
        }
    }
    Context 'cannot correct file contents' {
        Mock New-Item {}
        Mock Copy-Item {}
        Mock Test-FilePath -Verifiable {$true}
        Mock Process-Idempotent -Verifiable {
            [string]$Remedy -notmatch 'Out-File'
        }
        It 'throws correct exception when FileContents cannot be set.' {
            $splat = @{
                Path = @{
                    DriveLetter = 'a'
                    Segments = 'seg.txt'
                }
                ItemType = 'File'
                FileContents = 'contents'
            }

            try
            {
                Process-IdemFile Set @splat -ea Stop
            }
            catch [System.IO.FileNotFoundException]
            {
                $threw = $true
                $_.Exception.Message | Should match 'Set FileContents failed for a:\\seg.txt'
            }
            $threw | Should be $true
        }
    }
    Context 'success' {
        Mock New-Item {}
        Mock Copy-Item {}
        Mock Test-FilePath -Verifiable {$true}
        Mock Process-Idempotent -Verifiable {
            if ( [string]$Remedy -match 'Out-File' )
            {
                return [IdempotentResult]::RequiredChangesApplied
            }
            return [IdempotentResult]::NoChangeRequired
        }
        It 'returns the highest value result.' {
            $splat = @{
                Path = @{
                    DriveLetter = 'a'
                    Segments = 'seg.txt'
                }
                ItemType = 'File'
                FileContents = 'contents'
            }

            $r = Process-IdemFile Set @splat
            $r -eq [idempotentresult]::RequiredChangesApplied | Should be $true
        }
    }
}
}
}
Describe Remove-TrailingNewlines {
    It 'removes trailing newlines (1).' {
        $r = "asdf`r`n" | Remove-TrailingNewlines
        $r | Should be 'asdf'
    }
    It 'removes trailing newlines (2).' {
        $r = "asdf`r`n`r" | Remove-TrailingNewlines
        $r | Should be 'asdf'
    }
    It 'preserves mid-span newlines.' {
        $r = "asdf`r`n`rjkl;`r`n" | Remove-TrailingNewlines
        $r | Should be "asdf`r`n`rjkl;"
    }
}
