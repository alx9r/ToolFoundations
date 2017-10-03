Describe newlines {
    It 'System.Environment newline characters' {
        $r = [System.Environment]::NewLine.GetEnumerator() | % {[int]$_ }
        $r | Should be 13,10
    }
    Context 'here string' {
        It 'empty line is empty string' {
            @"

"@ |
            Should beNullOrEmpty
        }
        It 'two empty lines is system newline' {
            @"


"@ |
            Should be ([System.Environment]::NewLine)
        }
    }
    Context 'scriptblock' {
        It 'empty is empty string' {
            {}.ToString() | Should be ''
        }
        It 'newline is system newline' {
            {
}.ToString() |
            Should be ([System.Environment]::NewLine)
        }
        It 'empty line is two system newlines' {
            {

}.ToString() |
            Should be ([System.Environment]::NewLine*2)
        }
    }
}
