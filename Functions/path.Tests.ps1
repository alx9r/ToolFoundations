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
