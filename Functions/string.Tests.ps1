Describe "Expand-String" {
    BeforeEach {
        Remove-Module 'ToolFoundations' -ea SilentlyContinue
        Import-Module 'ToolFoundations'
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
}
