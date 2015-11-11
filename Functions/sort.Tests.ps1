Import-Module ToolFoundations -Force

Describe Sort-Hashtables {
    It 'correctly sorts hashtable[]' {
        $hl = @{a=3},@{a=4},@{a=1},@{a=2}

        $r = ,$hl | Sort-Hashtables 'a'
        $r -is [array] | Should be $true
        $r[0] -is [hashtable] | Should be $true
        $r[0] | Should be $hl[2]
        $r[1] | Should be $hl[3]
        $r[2] | Should be $hl[0]
        $r[3] | Should be $hl[1]
    }
    It 'puts items without matching keys at the beginning of the list.' {
        $hl = @{a=4},@{b=2},@{a=1},@{a=2}

        $r = ,$hl | Sort-Hashtables 'a'
        $r[0] | Should be $hl[1]
        $r[1] | Should be $hl[2]
        $r[2] | Should be $hl[3]
        $r[3] | Should be $hl[0]
    }
    It 'correctly handles multiple keys.' {
        $hl = @(
            @{a=1;b=20}
            @{a=2;b=1}
            @{a=1;b=10}
            @{a=2;b=2}
        )
        $r = ,$hl | Sort-Hashtables 'a','b'
        $r[0] | Should be $hl[2]
        $r[1] | Should be $hl[0]
        $r[2] | Should be $hl[1]
        $r[3] | Should be $hl[3]
    }
}
