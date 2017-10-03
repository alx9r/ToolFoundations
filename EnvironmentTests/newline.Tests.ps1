Describe newlines {
    It 'System.Environment newline characters' {
        $r = [System.Environment]::NewLine.GetEnumerator() | % {[int]$_ }
        $r | Should -Be 13,10
    }
    Context 'here string' {
        It 'empty line' {
            @"

"@ |
            Should -BeNullOrEmpty
        }
        It 'two empty lines' {
            @"


"@ |
            Should -Be "`r`n"
        }
    }
    Context 'scriptblock' {
        It 'empty' {
            {}.ToString() | Should -Be ''
        }
        It 'newline' {
            {
}.ToString() |
            Should -Be "`r`n"
        }
        It 'empty line' {
            {

}.ToString() |
            Should -Be "`r`n`r`n"
        }
    }
}
