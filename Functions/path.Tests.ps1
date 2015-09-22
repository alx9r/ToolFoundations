Import-Module ToolFoundations -Force

Describe Test-ValidDriveLetter {
    It 'returns true for good drive letter.' {
        'a' | Test-ValidDriveLetter | Should be $true
        'A' | Test-ValidDriveLetter | Should be $true
        'z' | Test-ValidDriveLetter | Should be $true
    }
    It 'returns false for bad drive letter.' {
        'aa' | Test-ValidDriveLetter | Should be $false
        '_' | Test-ValidDriveLetter | Should be $false
        '1' | Test-ValidDriveLetter | Should be $false
    }
}
Describe Test-ValidFilename{
    It 'returns true for valid filename.' {
        'a' | Test-ValidFileName | Should be $true
        'a.b' | Test-ValidFileName | Should be $true
    }
    It 'returns false for an invalid characters.' {
        'b<d' | Test-ValidFileName | Should be $false
        'b*d' | Test-ValidFileName | Should be $false
        'inva|id' | Test-ValidFileName | Should be $false
        'c:' | Test-ValidFileName | Should be $false
    }
    It 'returns false for all periods.' {
        '.' | Test-ValidFileName | Should be $false
        '..' | Test-ValidFileName | Should be $false
    }
    It 'returns false for DOS Names.' {
        'PRN.' | Test-ValidFileName | Should be $false
        'PRN' | Test-ValidFileName | Should be $false
        'AUX.txt' | Test-ValidFileName | Should be $false
        'AUXtxt' | Test-ValidFileName | Should be $true
    }
    It 'returns false for filename that is too long.' {
        $s = '0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789'+
        '0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789'+
        '0123456789012345678901234567890123456789012345678901234'

        $s.Length | Should be 255
        $s | Test-ValidFileName | Should be $true
        $s = $s+'5'
        $s.Length | Should be 256
        $s | Test-ValidFileName | Should be $false
    }
}
InModuleScope ToolFoundations {
    Describe Test-ValidFilePathFragment {
        It 'returns true.' {
            'good\frag' | Test-ValidFilePathFragment | Should be $true
            'good/frag' | Test-ValidFilePathFragment | Should be $true
        }
        it 'return false.' {
            'bad\path/fragment' | Test-ValidFilePathFragment | Should be $false
            'bad/pa:h/fragment' | Test-ValidFilePathFragment | Should be $false
        }
        Context 'validates good element' {
            Mock Test-ValidFileName -Verifiable {$true}
            It 'returns true.' {
                $r = 'good\frag' | Test-ValidFilePathFragment
                $r | Should be $true

                Assert-MockCalled Test-ValidFileName -Times 1 {
                    $FileName -eq 'good'
                }
                Assert-MockCalled Test-ValidFileName -Times 1 {
                    $FileName -eq 'frag'
                }
            }
        }
        Context 'validates bad element' {
            Mock Test-ValidFileName -Verifiable {$false}
            It 'returns true.' {
                $r = 'bad\frag' | Test-ValidFilePathFragment
                $r | Should be $false

                Assert-MockCalled Test-ValidFileName -Times 1 {
                    $FileName -eq 'bad'
                }
            }
        }
    }
}
Describe ConvertTo-FilePathWithoutPrefix {
    It 'PowerShell Windows path' {
        $r = 'c:\path' | ConvertTo-FilePathWithoutPrefix
        $r | Should be 'c:\path'
    }
    It 'UNC path' {
        $r = '\\server\path' | ConvertTo-FilePathWithoutPrefix
        $r | Should be '\\server\path'
    }
    It 'PowerShell Windows Path' {
        $r = 'FileSystem::c:\path' | ConvertTo-FilePathWithoutPrefix
        $r | Should be 'c:\path'
    }
    It 'long prefix PowerShell Windows Path' {
        $r = 'Microsoft.PowerShell.Core\FileSystem::c:\path' | ConvertTo-FilePathWithoutPrefix
        $r | Should be 'c:\path'
    }
    It 'PowerShell UNC Path' {
        $r = 'FileSystem::\\server\path' | ConvertTo-FilePathWithoutPrefix
        $r | Should be '\\server\path'
    }
    It 'long prefix PowerShell UNC Path' {
        $r = 'Microsoft.PowerShell.Core\FileSystem::\\server\path' | ConvertTo-FilePathWithoutPrefix
        $r | Should be '\\server\path'        
    }
    It 'URI Windows Path' {
        $r = 'file:///c:/path' | ConvertTo-FilePathWithoutPrefix
        $r | Should be 'c:/path'
    }
    It 'URI UNC Path' {
        $r = 'file://server/path' | ConvertTo-FilePathWithoutPrefix
        $r | Should be '//server/path'
    }
}
InModuleScope ToolFoundations {
    Describe Get-FilePathType {
        Context 'Windows path' {
            Mock ConvertTo-FilePathWithoutPrefix {'c:\path'}
            It 'returns correct type.' {
                $r = 'path' | Get-FilePathType
                $r | Should be 'windows'
            }
        }
        Context 'UNC path' {
            Mock ConvertTo-FilePathWithoutPrefix {'\\server\path'}
            It 'returns correct type' {
                $r = 'path' | Get-FilePathType
                $r | Should be 'UNC'
            }
        }
        Context 'strips prefix' {
            Mock ConvertTo-FilePathWithoutPrefix -Verifiable
            Mock Write-Error
            It 'invokes strip function' {
                $r = 'path' | Get-FilePathType
                
                Assert-MockCalled ConvertTo-FilePathWithoutPrefix -Times 1 {
                    $Path -eq 'path'
                }
            }
        }
        Context 'unidentified' {
            Mock ConvertTo-FilePathWithoutPrefix {'not a real path'}
            Mock Write-Error -Verifiable
            It 'reports correct error.' {
                $r = 'path' | Get-FilePathType
                $r | Should be $false

                Assert-MockCalled Write-Error -Times 1 {
                    $Message -eq 'Could not identify type of Path path'
                }
            }
        }
    }
}