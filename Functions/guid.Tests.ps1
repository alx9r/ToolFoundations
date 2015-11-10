Import-Module ToolFoundations -Force

Describe Test-ValidGuidString {

    It 'returns false for a bad guid (1)' {
        'not a guid' | Test-ValidGuidString |
            Should be $false
    }
    It 'returns false for a bad guid (2)' {
        '{XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX}' | Test-ValidGuidString |
            Should be $false
    }
    It 'returns false for a bad guid (3)' {
        'EF84912E-04A6-4CE8-A7AE-02C0B05469FB' | Test-ValidGuidString |
            Should be $true
    }
    It 'returns true for a good guid (1)' {
        '{12345678-1234-1234-1234-123456789012}' | Test-ValidGuidString |
            Should be $true
    }
    It 'returns true for a good guid (2)' {
        '{be4e57ea-2902-4c4b-8cdc-22064f9de5e0}' | Test-ValidGuidString |
            Should be $true
    }
    It 'returns true for a good guid (2)' {
        '{EF84912E-04A6-4CE8-A7AE-02C0B05469FB}' | Test-ValidGuidString |
            Should be $true
    }
}
