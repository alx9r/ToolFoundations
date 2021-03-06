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
            $_.Exception.Message | Should match 'Copying of directories is not supported.'
        }
        $threw | Should be $true
    }
    It 'throws correct exception when FileContent is provided for a Directory.' {
        $splat = @{
            Mode = 'set'
            Path = @{
                DriveLetter = 'a'
                Segments = 'path'
            }
            ItemType = 'Directory'
            FileContent = 'content'
        }
        try
        {
            Assert-ValidIdemFileParams @splat
        }
        catch [System.ArgumentException]
        {
            $threw = $true
            $_.Exception.Message | Should match 'FileContent provided for a directory.'
        }
        $threw | Should be $true
    }
    It 'throws correct exception when FileContent and CopyPath are provided.' {
        $splat = @{
            Mode = 'set'
            Path = @{
                DriveLetter = 'a'
                Segments = 'path'
            }
            ItemType = 'File'
            FileContent = 'content'
        }
        try
        {
            Assert-ValidIdemFileParams @splat
        }
        catch [System.ArgumentException]
        {
            $threw = $true
            $_.Exception.Message | Should match 'Both CopyPath and FileContent were provided.'
        }
    }
    Context 'coerce Path' {
        Mock CoerceTo-FilePathObject -Verifiable {}
        It 'attempts to coerce Path to string' {
            $splat = @{
                Mode = 'set'
                Path = New-FilePathObject -DriveLetter c -Segments seg -FilePathType Windows
                ItemType = 'File'
                FileContent = 'content'
            }
            Assert-ValidIdemFileParams @splat
            Assert-MockCalled CoerceTo-FilePathObject -Times 1 -ParameterFilter {
                $InputObject.DriveLetter -eq 'c' -and
                $InputObject.Segments -eq 'seg'
            }
        }
    }
    Context 'coerce CopyPath' {
        Mock Test-FilePathsAreEqual {$false}
        Mock CoerceTo-FilePathObject -Verifiable {}
        It 'attempts to coerce CopyPath to string' {
            $splat = @{
                Mode = 'set'
                Path = 'path'
                ItemType = 'File'
                CopyPath = New-FilePathObject -DriveLetter c -Segments seg -FilePathType Windows
            }
            Assert-ValidIdemFileParams @splat
            Assert-MockCalled CoerceTo-FilePathObject -Times 1 -ParameterFilter {
                $InputObject.DriveLetter -eq 'c' -and
                $InputObject.Segments -eq 'seg'
            }
        }
    }
}
Describe 'Process-IdemFile' {
    Mock New-Item {}
    Mock Copy-Item {}
    Mock Out-File {}
    Context 'nothing at CopyPath' {
        Mock Test-FilePath -Verifiable {$false}
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

            { Process-IdemFile Set @splat -ea Stop } |
                Should throw 'CopyPath b:\seg does not exist.'

            Assert-MockCalled Test-FilePath -Times 1 {
                $PathObject.DriveLetter -eq 'b' -and
                $ItemType -eq 'File'
            }
        }
    }
    Context 'Get-Filehash' {
        Mock Test-FilePath {$true}
        Mock Get-FileHash -Verifiable
        Mock Invoke-ProcessIdempotent {$true}
        It 'correctly calls file hash.' {
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

            Process-IdemFile Test @splat

            Assert-MockCalled Get-FileHash -Times 1 -Exactly {
                $Path -eq 'b:\seg'
            }
        }
    }
}
Describe 'Process-IdemFile Set' {
    Mock New-Item {}
    Mock Copy-Item {}
    Mock Out-File {}
    Context 'cannot set Path' {
        Mock Test-FilePath -Verifiable {$true}
        Mock Invoke-ProcessIdempotent -Verifiable {$false}
        It 'throws correct exception when Path cannot be set.' {
            $splat = @{
                Path = @{
                    DriveLetter = 'a'
                    Segments = 'seg.txt'
                }
                ItemType = 'File'
            }

            {Process-IdemFile Set @splat -ea Stop} |
                Should throw 'Set failed for a:\seg.txt.'
        }
    }
    Context 'cannot correct file content' {
        Mock Test-FilePath -Verifiable {$true}
        Mock Invoke-ProcessIdempotent -Verifiable {
            [string]$Remedy -notmatch 'Out-File'
        }
        It 'throws correct exception when FileContent cannot be set.' {
            $splat = @{
                Path = @{
                    DriveLetter = 'a'
                    Segments = 'seg.txt'
                }
                ItemType = 'File'
                FileContent = 'content'
            }

            {Process-IdemFile Set @splat -ea Stop} |
                Should throw 'Set FileContent failed for a:\seg.txt'
        }
    }
    Context 'success' {
        Mock Test-FilePath -Verifiable {$true}
        Mock Invoke-ProcessIdempotent -Verifiable {
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
                FileContent = 'content'
            }

            $r = Process-IdemFile Set @splat
            $r -eq [idempotentresult]::RequiredChangesApplied | Should be $true
        }
    }
    Context 'CopyPath Remedy' {
        Mock Test-FilePath {$true}
        Mock Get-FileHash {
            New-Object psobject -Property @{
                Hash = 'hash'
                Algorithm = 'SHA256'
            }
        }
        Mock Test-FileHash {$false}
        Mock Copy-Item -Verifiable {}
        It 'correctly calls Copy-Item.' {
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
            catch [System.IO.FileNotFoundException]{}

            Assert-MockCalled Copy-Item -Times 1 -Exactly {
                $Path -eq 'b:\seg' -and
                $Destination -eq 'a:\seg'
            }
        }
    }
    Context 'FileContent Remedy (New-Item)' {
        Mock Test-FilePath {$false}
        Mock New-Item -Verifiable
        It 'correctly calls New-Item.' {
            $splat = @{
                Path = @{
                    DriveLetter = 'a'
                    Segments = 'seg'
                }
                ItemType = 'File'
                FileContent = 'content'
            }
            {Process-IdemFile Set @splat -ea Stop} |
                Should throw 'Set failed for a:\seg.'

            Assert-MockCalled New-Item -Times 1 -Exactly {
                $Path -eq 'a:\seg' -and
                $ItemType -eq 'File'
            }
        }
    }
    Context 'FileContent Remedy (Out-File)' {
        Mock Test-FilePath {$true}
        Mock Compare-FileContent {$false}
        Mock Out-File -Verifiable
        It 'correctly calls Out-File.' {
            $splat = @{
                Path = @{
                    DriveLetter = 'a'
                    Segments = 'seg'
                }
                ItemType = 'File'
                FileContent = 'content'
            }
            {Process-IdemFile Set @splat -ea Stop}|
                Should throw 'Set FileContent failed for a:\seg.'

            Assert-MockCalled Out-File -Times 1 -Exactly {
                $FilePath -eq 'a:\seg' -and
                $Encoding -eq 'ascii' -and
                $InputObject -eq 'content'
            }
        }
    }
    Context 'CreateParentFolders' {
        Mock Test-FilePath -Verifiable
        Mock New-Item -Verifiable
        It 'correctly calls New-Item.' {
            $splat = @{
                Path = @{
                    DriveLetter = 'a'
                    Segments = 'exists','implied','folder'
                }
                ItemType = 'Directory'
                CreateParentFolders = $true
            }
            {Process-IdemFile Set @splat -ea Stop} |
                Should throw 'Set failed'

            Assert-MockCalled New-Item -Times 1 -Exactly {
                $Path -eq 'a:\exists\implied\folder' -and
                $ItemType -eq 'Directory' -and
                $Force
            }
        }
    }
    Context 'CreateParentFolders (CopyPath)' {
        Mock Test-FilePath -Verifiable {$PathObject.DriveLetter -eq 'c'}
        Mock New-Item -Verifiable
        Mock Test-FileHash
        Mock Get-FileHash {
            New-Object psobject -Property @{
                Hash = 'hash'
                Algorithm = 'SHA256'
            }
        }
        It 'correctly calls New-Item.' {
            $splat = @{
                Path = @{
                    DriveLetter = 'a'
                    Segments = 'exists','implied','file.txt'
                }
                ItemType = 'File'
                CreateParentFolders = $true
                CopyPath = @{
                    DriveLetter = 'c'
                    Segments = 'seg'
                }
            }
            try
            {
                Process-IdemFile Set @splat -ea Stop
            }
            catch [System.IO.FileNotFoundException]
            {
                $threw = $true
                $_.Exception.Message | Should match 'Set failed'
            }
            $threw | Should be $true

            Assert-MockCalled Test-FilePath -Times 1 -Exactly {
                $PathObject.Segments[-1] -eq 'implied'
            }
            Assert-MockCalled New-Item -Times 1 -Exactly {
                $Path -eq 'a:\exists\implied' -and
                $ItemType -eq 'Directory' -and
                $Force
            }
        }
    }
}
Describe 'Process-IdemFile Test' {
    Mock New-Item {}
    Mock Copy-Item {}
    Mock Out-File {}
    Context 'CopyPath Test' {
        Mock Test-FilePath -Verifiable {$true}
        Mock Get-FileHash {
            New-Object psobject -Property @{
                Algorithm = 'SHA256'
                Hash = 'hash'
            }
        }
        Mock Test-FileHash -Verifiable {$true}
        It 'correctly calls Test-FileHash.' {
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
            Process-IdemFile Test @splat -ea Stop

            Assert-MockCalled Test-FileHash -Times 1 -Exactly {
                $Algorithm -eq 'SHA256' -and
                $Hash -eq 'hash' -and
                $Path -eq 'a:\seg'
            }
        }
    }
    Context 'FileContent Test' {
        Mock Test-FilePath -Verifiable {$true}
        Mock Compare-FileContent -Verifiable {$true}
        It 'correctly calls Test-FilePath and Compare-FileContent' {
            $splat = @{
                Path = @{
                    DriveLetter = 'a'
                    Segments = 'seg'
                }
                ItemType = 'File'
                FileContent = 'content'
            }
            Process-IdemFile Test @splat -ea Stop

            Assert-MockCalled Test-FilePath -Times 1 -Exactly {
                $PathObject.DriveLetter -eq 'a'
            }
            Assert-MockCalled Compare-FileContent -Times 1 -Exactly {
                $Path.DriveLetter -eq 'a' -and
                $Content -eq 'content'
            }
        }
    }
}
Describe Test-FileHash {
    Context 'no file' {
        Mock Test-Path -Verifiable {$false}
        It 'returns false.' {
            $splat = @{
                Hash = 'hash'
                Algorithm = 'SHA256'
                Path = 'a:\path.txt'
            }
            $r = Test-FileHash @splat

            $r | Should be $false

            Assert-MockCalled Test-Path -Times 1 -Exactly {
                $Path -eq 'a:\path.txt'
            }
        }
    }
    Context 'hash mismatch' {
        Mock Test-Path -Verifiable {$true}
        Mock Get-FileHash -Verifiable {
            New-Object psobject -Property @{
                Hash = 'some hash'
            }
        }
        It 'returns false.' {
            $splat = @{
                Hash = 'other hash'
                Algorithm = 'SHA256'
                Path = 'a:\path.txt'
            }
            $r = Test-FileHash @splat

            $r | Should be $false

            Assert-MockCalled Get-FileHash -Times 1 -Exactly {
                $LiteralPath -eq 'a:\path.txt' -and
                $Algorithm -eq 'SHA256'
            }
        }
    }
    Context 'success' {
        Mock Test-Path -Verifiable {$true}
        Mock Get-FileHash -Verifiable {
            New-Object psobject -Property @{
                Hash = 'hash'
            }
        }
        It 'returns false.' {
            $splat = @{
                Hash = 'hash'
                Algorithm = 'SHA256'
                Path = 'a:\path.txt'
            }
            $r = Test-FileHash @splat

            $r | Should be $true
        }
    }
}
Describe Compare-FileContent {
    Context 'no file' {
        Mock Test-FilePath -Verifiable {$false}
        It 'returns false' {
            $splat = @{
                Content = ''
                Path = @{
                    DriveLetter = 'a'
                    Segments = 'seg'
                }
            }

            $r = Compare-FileContent @splat
            $r | Should be $false

            Assert-MockCalled Test-FilePath -Times 1 -Exactly {
                $PathObject.DriveLetter -eq 'a'
            }
        }
    }
    Context 'match' {
        Mock Test-FilePath {$true}
        Mock Get-RawContent -Verifiable {'content'}
        It 'returns true' {
            $splat = @{
                Content = 'content'
                Path = @{
                    DriveLetter = 'a'
                    Segments = 'seg'
                }
            }

            $r = Compare-FileContent @splat
            $r | Should be $true

            Assert-MockCalled Get-RawContent -Times 1 -Exactly {
                $Path -eq 'a:\seg'
            }
        }
    }
    Context 'empty file' {
        Mock Test-FilePath {$true}
        Mock Get-RawContent -Verifiable {}
        It 'returns true' {
            $splat = @{
                Content = ''
                Path = @{
                    DriveLetter = 'a'
                    Segments = 'seg'
                }
            }

            $r = Compare-FileContent @splat
            $r | Should be $true

            Assert-MockCalled Get-RawContent -Times 1 -Exactly {
                $Path -eq 'a:\seg'
            }
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
    It 'works with empty strings.' {
        $r = [string]::Empty | Remove-TrailingNewlines
        $r -eq [string]::Empty
    }
}
