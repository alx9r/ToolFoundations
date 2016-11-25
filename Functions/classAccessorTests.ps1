Import-Module ToolFoundations -Force

Describe Get-AccessorPropertyName {
    function f { return $MyInvocation }
    Context 'good values' {
        foreach ( $string in @(
                '$_p = Accessor'
                '$_p = $(Accessor)'
                '$_p = $(Accessor {})'
                '$_p = $(Accessor { get { $this._p }; set { $this._p = "value" })'
                '$_p = $(Accessor $this {',
                '$_p=$(Accessor $this {',
                '$_p=Accessor { get { $this._p }; set { $this._p = "value" }'
                'hidden $_p = Accessor'
                'hidden [string] $_p = Accessor'
            )
        )
        {
            It $string {
                $r = $string | Get-AccessorPropertyName
                $r | Should be 'p'
            }
        }
    }
    Context 'throw special exception for missing underscore' {
        foreach ( $string in @(
                '$p = Accessor'
                '$p = $(Accessor)'
                '$p = $(Accessor {})'
                '$p = $(Accessor { get { $this._p }; set { $this._p = "value" })'
                '$p = $(Accessor $this {',
                '$p=$(Accessor $this {',
                '$p=Accessor { get { $this._p }; set { $this._p = "value" }'
                'hidden $p = Accessor'
                'hidden [string] $p = Accessor'
            )
        )
        {
            It $string {
                { $string | Get-AccessorPropertyName } |
                    Should throw 'Missing underscore in property name'
            }
        }
    }
    Context 'bad values' {
        foreach ( $string in @(
                '$_p'
            )
        )
        {
            It $string {
                { $string | Get-AccessorPropertyName } |
                    Should throw 'does not contain any captures'
            }
        }
    }
}

Describe 'Accessor using psobject' {
    BeforeEach {
        $o = New-Object psobject -Property @{f=$null}
    }
    It 'returns only initializer values' {
        $_r = Accessor $o {$this.f = 'value';'initializerValue'}
        $_r -is [string] | Should be $true
        $_r | Should be 'initializerValue'
    }
    It 'object accessible as $this' {
        $_r = Accessor $o {$this.f = 'value'}
        $o.f | Should be 'value'
    }
    It 'object accessible as $this in getter' {
        $_r = Accessor $o { get {$this.f = 'value'} }
        $r = $o.r
        $o.f | Should be 'value'
    }
    It 'object accessible as $this in setter' {
        $_r = Accessor $o {
            set {
                $this.f = 'value'
            }
        }
        $o.r = 'another value'
        $o.f | Should be 'value'
    }
    It 'original set alias is still available' {
        $r = Get-Alias set
        $r.Definition | Should be 'Set-Variable'
    }
    It 'exception in setter is raised to user' {
        $_r = Accessor $o { set { throw 'setter exception' } }
        { $o.r = 'some value' } |
            Should throw 'setter exception'
    }
    It 'exception in getter is suppressed' {
        $_r = Accessor $o { get { throw 'getter exception' } }
        { $o.r } | Should not throw
    }
}
Describe 'Accessor using classes' {
    Context 'get' {
        class c {
            $f = 'value'
            $_p = $(Accessor $this { get { $this.f } })
        }
        It '$this accessible from scriptblock' {
            $c = [c]::new()
            $c.p | Should be 'value'
        }
    }
    Context 'set' {
        class c {
            $f
            $_p = $(Accessor $this { set { $this.f = 'value' } })
        }
        It '$this accessible from scriptblock' {
            $c = [c]::new()
            $c.p = 'value'
            $c.f | Should be 'value'
        }
    }
    Context 'empty get and set' {
        class c {
            $_p = $(Accessor $this { get; set; 10})
        }
        $c = [c]::new()
        It 'initializes' {
            $c._p | Should be 10
        }
        It 'gets' {
            $r = $c.p
            $r | Should be 10
        }
        It 'sets' {
            $c.p = 11
            $c._p | Should be 11
            $c.p | Should be 11
        }
    }
    Context 'empty set, no get' {
        class c {
            $_p = $(Accessor $this { set; 10})
        }
        $c = [c]::new()
        It 'initializes' {
            $c._p | Should be 10
        }
        It 'get returns $null' {
            $r = $c.p
            $null -eq $r | Should be $true
        }
        It 'sets' {
            $c.p = 11
            $c._p | Should be 11
        }
    }
    Context 'empty get, no set' {
        class c {
            $_p = $(Accessor $this { get; 10 })
        }
        $c = [c]::new()
        It 'initializes' {
            $c._p | Should be 10
        }
        It 'gets' {
            $c.p | Should be 10
        }
        It 'invoking set throws' {
            { $c.p = 11 } |
                Should throw 'Set accessor for property "p" is unavailable.'
        }
    }
    Context 'custom set, empty get' {
        class c {
            $_p = $(Accessor $this {
                set { param($p) $this._p = "CustomSet$p" }
                get
                10
            })
        }
        $c = [c]::new()
        It 'initializes' {
            $c._p | Should be 10
        }
        It 'gets' {
            $c.p | Should be 10
        }
        It 'sets' {
            $c.p = 'Value'
            $c._p | Should be 'CustomSetValue'
            $c.p | Should be 'CustomSetValue'
        }
    }
    Context 'custom get, empty set' {
        class c {
            $_p = $(Accessor $this {
                set
                get { "CustomGet$($this._p)" }
                'Value'
            })
        }
        $c = [c]::new()
        It 'initializes' {
            $r = $c._p
            $r | Should be 'Value'
        }
        It 'gets' {
            $c.p | Should be 'CustomGetValue'
        }
        It 'sets' {
            $c.p = 'AnotherValue'
            $c._p | Should be 'AnotherValue'
        }
    }
}

Describe 'Accessor property name' {
    Context 'not p' {
        class c {
            $_q = $(Accessor $this {})
        }
        It 'creates scriptproperty' {
            $c = [c]::new()
            $r = $c | Get-Member 'q'
            $r | Should not beNullOrEmpty
        }
    }
    Context 'no underscore' {
        It 'throws if there is no underscore' {
            try
            {
                $p = (Accessor (New-Object psobject) {})
            }
            catch
            {
                $threw = $true
                $_.Exception | Should match 'Missing underscore in property name at'
            }
            $threw | Should be $true
        }
        It 'exception includes correct file name' {}
        It 'exception includes correct line number' {}
    }
}

Describe 'Accessor alternate syntax' {
    Context 'no $' {
        class c {
            $_p = (Accessor $this { 10; get; })
        }
        $c = [c]::new()
        It 'initializes' {
            $c._p | Should be 10
        }
        It 'gets' {
            $c.p | Should be 10
        }
        It 'set throws' {
            { $c.p = 20 } |
                Should throw 'Set accessor for property "p" is unavailable'
        }
    }
}
