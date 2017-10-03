Describe newlines {
    It 'System.Environment newline characters' {
        $r = [System.Environment]::NewLine.GetEnumerator() | % {[int]$_ }
        $r | Should be 13,10
    }
    Context 'here string' {
        It 'empty line' {
            @"

"@ |
            Should beNullOrEmpty
        }
        It 'two empty lines' {
            @"


"@ |
            Should be "`r`n"
        }
    }
    Context 'scriptblock' {
        It 'empty' {
            {}.ToString() | Should be ''
        }
        It 'newline' {
            {
}.ToString() |
            Should be "`r`n"
        }
        It 'empty line' {
            {

}.ToString() |
            Should be "`r`n`r`n"
        }
    }
}
