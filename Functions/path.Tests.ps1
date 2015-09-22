Describe Test-ValidDriveLetter {
    BeforeEach {
        Remove-Module ToolFoundations -ea SilentlyContinue
        Import-Module ToolFoundations
    }

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
    BeforeEach {
        Remove-Module ToolFoundations -ea SilentlyContinue
        Import-Module ToolFoundations
    }

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
    Describe Test-ValidPathFragment {
        It 'returns true.' {
            'good\frag' | Test-ValidPathFragment | Should be $true
            'good/frag' | Test-ValidPathFragment | Should be $true
        }
        it 'return false.' {
            'bad\path/fragment' | Test-ValidPathFragment | Should be $false
            'bad/pa:h/fragment' | Test-ValidPathFragment | Should be $false
        }
        Context 'validates good element' {
            Mock Test-ValidFileName -Verifiable {$true}
            It 'returns true.' {
                $r = 'good\frag' | Test-ValidPathFragment
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
                $r = 'bad\frag' | Test-ValidPathFragment
                $r | Should be $false

                Assert-MockCalled Test-ValidFileName -Times 1 {
                    $FileName -eq 'bad'
                }
            }
        }
    }
}
