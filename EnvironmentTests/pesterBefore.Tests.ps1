$h = @{}
$h.i = 0
Describe 'BeforeEach in this block' {
    BeforeEach {
        $h.i = $h.i+1
    }
    It 'invokes BeforeEach' {
        $h.i | Should be 1
    }
    It 'invokes BeforeEach' {
        $h.i | Should be 2
    }
}
Describe 'No BeforeEach in this block' {
    It 'does not invoke BeforeEach from previous block' {
        $h.i | Should be 2
    }
}
