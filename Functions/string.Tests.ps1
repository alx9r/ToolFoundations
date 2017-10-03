Import-Module ToolFoundations -Force

Describe "Expand-String" {
    BeforeEach {
        $MyString = 'The $animal says $sound.'
        $animal = 'fox'
        $sound = 'simper'
        $FoxSimper = 'The fox says simper.'
    }

    It "outputs [scriptblock]" {
        (Expand-String 'foo').GetType() | Should Be {}.GetType()
    }

    It "produces an expanding string using pipeline" {
        &($MyString | xs) | Should Be $FoxSimper
    }

    It "produces an expanding string using positional a parameter" {
        &(xs $MyString)   | Should Be $FoxSimper
    }

    It "produces an expanding string using named parameter" {
        &(xs -String $MyString)   | Should Be $FoxSimper
    }

    It "throws on missing parameter" {
        { xs } | Should Throw
    }

    It "throws on null positional parameter" {
        { xs $null } | Should Throw
    }

    It "throws on null pipeline parameter" {
        { $null | xs } | Should Throw
    }

    It "correctly escapes quotes in string" {
        &(xs 'yeah, "the".') | Should be 'yeah, "the".'
    }

    It "assert backticks handling" {
        &(xs 'this is a tab:`t, this backtick disappears:` ') |
        Should be 'this is a tab:	, this backtick disappears: '
    }
    if ( $PSVersionTable.PSVersion.Major -le 2 )
    {
        It 'eats single quotes.' {
            &(xs "these 'single quotes' get eaten") |
                Should be 'these single quotes get eaten'
        }
    }
    else
    {
        It "handles 'single quotes' correctly" {
            &(xs "these are 'single quotes' here") |
                Should be "these are 'single quotes' here"
        }
    }
}

Describe Get-FileNewline {
    It 'same as <n>' -TestCases @(
       @{ n='here string @""@'; s= @"


"@.ToString() }
       @{ n="here string @''@"; s= @'


'@.ToString() }
       @{ n='scriptblock'; s={
}.ToString() }
    ) {
        param($n,$s)
        $r = Get-FileNewline
        $r | Should be $s
    }
}

InModuleScope ToolFoundations {

Describe Convert-Newline {
    Mock Get-FileNewline { [System.Environment]::NewLine+"`n" }
    $system = 'a'+[System.Environment]::NewLine+'b'
    $file = 'a'+(Get-FileNewline)+'b'
    It 'converts <s> to <t>' -TestCases @(
        @{s='System';t='File'}
        @{s='File';    t='System'}
    ){
        param($s,$t)
        $source = Get-Variable $s -ValueOnly
        $target = Get-Variable $t -ValueOnly

        $r = $source | Convert-Newline -To $t
        $r | Should be $target
    }
}
}
