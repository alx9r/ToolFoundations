Import-Module ToolFoundations -Force

InModuleScope ToolFoundations {
if ($PSVersionTable.PSVersion.Major -ge 4)
{
Describe Process-IdemSignedScript {
    Mock Invoke-ProcessIdemFile {}
    Mock Set-AuthenticodeSignature {}
    Context 'Test FileContent' {
        Mock Compare-SignedScriptContent -Verifiable
        It 'correctly calls Compare-SignedScriptContent' {
            $splat = @{
                Certificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
                Path = @{
                    DriveLetter = 'a'
                    Segments = 'seg'
                }
                FileContent = 'content'
            }
            Process-IdemSignedScript Test @splat

            Assert-MockCalled Compare-SignedScriptContent -Times 1 -Exactly {
                $ScriptPath.DriveLetter -eq 'a' -and
                $RefContent -eq 'content'
            }
        }
    }
    Context 'Test Signature' {
        Mock Compare-SignedScriptContent {$true}
        Mock Test-ValidScriptSignature -Verifiable
        It 'correctly calls Test-ValidScriptSignature' {
            $splat = @{
                Certificate = New-Object System.Security.Cryptography.X509Certificates.x509Certificate2
                Path = @{
                    DriveLetter = 'a'
                    Segments = 'seg'
                }
                FileContent = 'content'
            }
            Process-IdemSignedScript Test @splat

            Assert-MockCalled Test-ValidScriptSignature -Times 1 -Exactly {
                $ScriptPath.DriveLetter -eq 'a'
            }
        }
    }
    Context 'Remedy FileContent' {
        Mock Compare-SignedScriptContent {$false}
        Mock Invoke-ProcessIdemFile -Verifiable
        It 'correctly calls Invoke-ProcessIdemFile.' {
            $splat = @{
                Certificate = New-Object System.Security.Cryptography.X509Certificates.x509Certificate2
                Path = @{
                    DriveLetter = 'a'
                    Segments = 'seg'
                }
                FileContent = 'content'
            }
            Process-IdemSignedScript Set @splat

            Assert-MockCalled Invoke-ProcessIdemFile -Times 1 -Exactly {
                $Mode -eq 'Set' -and
                $Path.DriveLetter -eq 'a' -and
                $ItemType -eq 'File' -and
                $FileContent -eq 'content'
            }
        }
    }
    Context 'Remedy Signature' {
        Mock Compare-SignedScriptContent {$true}
        Mock Test-ValidScriptSignature {$false}
        Mock Set-AuthenticodeSignature -Verifiable
        It 'correctly calls Set-AuthenticodeSignature.' {
            $splat = @{
                Certificate = New-Object System.Security.Cryptography.X509Certificates.x509Certificate2
                Path = @{
                    DriveLetter = 'a'
                    Segments = 'seg'
                }
                FileContent = 'content'
            }
            Process-IdemSignedScript Set @splat

            Assert-MockCalled Set-AuthenticodeSignature -Times 1 -Exactly {
                $FilePath -eq 'a:\seg'
            }
        }
    }
    Context 'success' {
        $stack = [System.Collections.Stack]@(2,1)
        Mock Process-Idempotent {$stack.Pop()}
        It 'returns the highest return value.' {
            $splat = @{
                Certificate = New-Object System.Security.Cryptography.X509Certificates.x509Certificate2
                Path = @{
                    DriveLetter = 'a'
                    Segments = 'seg'
                }
                FileContent = 'content'
            }
            $r = Process-IdemSignedScript Set @splat
            $r | Should be 2
            $r.Count | Should be 1
        }
    }
}
Describe Compare-SignedScriptContent {
    It 'matches contents after signing (1).' {
        $pathObj = "$($PSCommandPath | Split-Path -Parent)\..\Resources\signature-test-1.ps1" |
            Resolve-FilePath |
            ConvertTo-FilePathObject
        $pathHash = @{
            DriveLetter = $pathObj.DriveLetter
            Segments = $pathObj.Segments
        }
        $splat = @{
            ScriptPath = $pathHash
            RefContent = @'
trailing newline

'@
        }
        $r = Compare-SignedScriptContent @splat
        $r | Should be $true
    }
    It 'matches contents after signing (2).' {
        $pathObj = "$($PSCommandPath | Split-Path -Parent)\..\Resources\signature-test-2.ps1" |
            Resolve-FilePath |
            ConvertTo-FilePathObject
        $pathHash = @{
            DriveLetter = $pathObj.DriveLetter
            Segments = $pathObj.Segments
        }
        $splat = @{
            ScriptPath = $pathHash
            RefContent = 'no trailing newline'
        }
        $r = Compare-SignedScriptContent @splat
        $r | Should be $true
    }
    It 'fails.' {
        $pathObj = "$($PSCommandPath | Split-Path -Parent)\..\Resources\signature-test-2.ps1" |
            Resolve-FilePath |
            ConvertTo-FilePathObject
        $pathHash = @{
            DriveLetter = $pathObj.DriveLetter
            Segments = $pathObj.Segments
        }
        $splat = @{
            ScriptPath = $pathHash
            RefContent = 'this does not match'
        }
        $r = Compare-SignedScriptContent @splat
        $r | Should be $false
    }
    Context 'empty file' {
        Mock Get-RawContent {}
        It 'handles empty script file.' {
            $splat = @{
                ScriptPath = @{
                    DriveLetter = 'a'
                    Segments = 'path.ps1'
                }
                RefContent = 'content'
            }
            $r = Compare-SignedScriptContent @splat
            $r | Should be $false
        }
    }
    Context 'empty file' {
        Mock Get-RawContent {}
        It 'handles empty script file and empty string.' {
            $splat = @{
                ScriptPath = @{
                    DriveLetter = 'a'
                    Segments = 'path.ps1'
                }
                RefContent = [string]::Empty
            }
            $r = Compare-SignedScriptContent @splat
            $r | Should be $true
        }
    }
}
}
}
