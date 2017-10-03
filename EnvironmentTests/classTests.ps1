Describe 'properties' {
    Context 'plain property' {
        class c { $p }
        $c = [c]::new()
        $d = [c]::new()
        It 'the variable is a property' {
            $r = Get-Member -InputObject $c -MemberType Property
            $r.Name | Should be 'p'
            $r.Count | Should be 1
        }
        It 'the property has a getter' {
            $r = Get-Member -InputObject $c -Name 'get_p' -Force
            $r.MemberType | Should match 'Method'
        }
        It 'the property has a setter' {
            $r = Get-Member -InputObject $c -Name 'set_p' -Force
            $r.MemberType | Should match 'Method'
        }
        It 'the property starts out empty' {
            $c.p | Should beNullOrEmpty
        }
        It 'the property can be set' {
            $c.p = 'value'
        }
        It 'the property can be retrieved' {
            $c.p | Should be 'value'
        }
        It 'each object has its own property' {
            $d.p = 'another value'
            $c.p | Should be 'value'
            $c.p = 'yet another value'
            $d.p | Should be 'another value'
        }
    }
    Context 'default value' {
        class c { $p = 1 }
        $c = [c]::new()
        It 'the property is initalized on object creation' {
            $c.p | Should be 1
        }
        It 'the property can be changed' {
            $c.p = 2
            $c.p | Should be 2
        }
    }
    Context 'access $this in initializer' {
        class c {
            $p1 = 'val1'
            $p2 = "$($this.p1)val2"
            $p4 = "$($this.p3)val4"
            $p3 = 'val3'
        }
        $c = [c]::new()
        It 'one property can access another property in its initializer' {
            $c.p2 | Should be 'val1val2'
        }
        It 'but beware of initialization order' {
            $c.p4 | Should be 'val4'
        }
    }
    Context 'typed' {
        class c { [string] $p }
        $c = [c]::new()
        It 'coercion happens on assignment to property' {
            $c.p = 2.0
            $c.p | Should beOfType string
            $c.p | Should be '2'
        }
    }
    Context 'hidden property' {
        class c { hidden $p }
        $c = [c]::new()
        It 'the variable is hidden' {
            $r = Get-Member -InputObject $c -MemberType Property
            $r.Name | Should beNullOrEmpty
        }
        It 'but you can force visibility' {
            $r = Get-Member -InputObject $c -MemberType Property -Force
            $r.Name | Should be 'p'
            $r.Count | Should be 1
        }
        It 'the property has a getter' {
            $r = Get-Member -InputObject $c -Name 'get_p' -Force
            $r.MemberType | Should match 'Method'
        }
        It 'the property has a setter' {
            $r = Get-Member -InputObject $c -Name 'set_p' -Force
            $r.MemberType | Should match 'Method'
        }
        It 'the property can be set as usual' {
            $c.p = 'value'
        }
        It 'the property can be retrieved as usual' {
            $c.p | Should be 'value'
        }
    }
    Context 'override setter and getter using set_p()/get_p()' {
        class c {
            $p
            set_p($arg) { $this.p = "setter $arg" }
            [object] get_p() { return $this.p }
        }
        $c = [c]::new()
        It 'the property has only one getter' {
            $r = Get-Member -InputObject $c -Name 'get_p' -Force
            $r.Count | Should be 1
            $r.MemberType | Should match 'Method'
        }
        It 'the property has only one setter' {
            $r = Get-Member -InputObject $c -Name 'set_p' -Force
            $r.Count | Should be 1
            $r.MemberType | Should match 'Method'
        }
        It 'the setter is not overridden' {
            $c.p = 'arg value'
            $c.p | Should be 'arg value'
        }
    }
    Context 'virtual property using get_p() (simple)' {
        class c {
            [object] get_p() { return '' }
        }
        $c = [c]::new()
        It 'the object has no property p' {
            $r = Get-Member -InputObject $c -Name 'p' -Force
            $r | Should beNullOrEmpty
        }
    }
    Context 'virtual property using get_p() (using inheritance)' {
        class Ip {
            $p = 'value Ip'
        }
        class c : Ip {
            [object] get_p() { return 'value c' }
        }
        $c = [c]::new()
        It 'getting object does not invoke getter' {
            $r = $c.p
            $r | Should be 'value Ip'
        }
    }
    Context 'override setter and getter using Add-Members' {
        class c {
            hidden $_p
            c() {
                $this | Add-Member ScriptProperty 'p' `
                {
                    # get
                    "getter $($this._p)"
                }`
                {
                    # set
                    param ( $arg )
                    $this._p = "setter $arg"
                }
            }
        }
        $c = [c]::new()
        It 'the property is a scriptproperty' {
            $r = Get-Member -InputObject $c -Name 'p'
            $r.MemberType | Should match 'ScriptProperty'
        }
        It 'the setter works as expected' {
            $c.p = 'arg value'
            $c.p | Should be 'getter setter arg value'
        }
    }
    Context 'override setter and getter using Add-Members (alternate syntax)' {
        class c {
            hidden $_p = $($this | Add-Member ScriptProperty 'p' {
                    # get
                    "getter $($this._p)"
                } {
                    # set
                    param ( $arg )
                    $this._p = "setter $arg"
                })
        }
        $c = [c]::new()
        It 'the property is a scriptproperty' {
            $r = Get-Member -InputObject $c -Name 'p'
            $r.MemberType | Should match 'ScriptProperty'
        }
        It 'the setter works as expected' {
            $c.p = 'arg value'
            $c.p | Should be 'getter setter arg value'
        }
    }
    Context 'static property' {
        $guid = [guid]::NewGuid().Guid.Replace('-','')
        iex "class c$guid { static `$p }"
        $c = New-Object "c$guid"
        It 'the variable is not revealed as a property' {
            $r = Get-Member -InputObject $c -MemberType Property
            $r | Should beNullOrEmpty
        }
        It 'visibility of the variable cannot be forced' {
            $r = Get-Member -InputObject $c -MemberType Property -Force
            $r | Should beNullOrEmpty
        }
        It 'the property cannot be set' {
            { $c.p = 'value' } |
                Should throw
        }
        It 'accessing the property returns null' {
            $c.p | Should beNullOrEmpty
        }
        It 'the property can be retrieved using the type accelerator and starts out empty' {
            iex "[c$guid]::p" | Should beNullOrEmpty
        }
        It 'the property can be set using the type accelerator' {
            iex "[c$guid]::p = 'value' "
        }
        It 'the property can be retrieved using the type accelerator' {
            iex "[c$guid]::p" | Should be 'value'
        }
    }
}
Describe 'methods' {
    Context 'plain method' {
        class c {
            $p
            m () {}
        }
        $c = [c]::new()
        It 'the function is revealed as a method using Get-Method' {
            $r = Get-Member -InputObject $c -MemberType Method |
                ? { $_.Name -eq 'm' }
            $r.Count | Should be 1
        }
        It 'the function is revealed as a method using reflection' {
            $r = $c.m
            $r.MemberType | Should be 'Method'
        }
        It 'the function''s return type is void' {
            $r = $c.m
            $r.Value | Should match '^void'
        }
    }
    Context 'return values' {
        It 'plain method doesn''t pass item dropped into pipeline' {
            class c { m() {'item' } }
            $c = [c]::new()
            $c.m() | Should beNullOrEmpty
        }
        It 'object return type doesn''t pass item dropped into pipeline' {
            class c {
                [object] m() { 'item for pipeline'; return 'return item' }
            }
            $c = [c]::new()
            $c.m() | Should be 'return item'
            $c.m() | Should beOfType string
        }
        It 'return coerces type' {
            class c { [string] m() { return 2.0 } }
            $c = [c]::new()
            $c.m() | Should be '2'
            $c.m() | Should beOfType string
        }
    }
    Context 'access properties' {
        class c {
            $p = 1
            [object] SetP() { $this.p = 2 ; return $null }
            [object] GetP() { return $this.p }
        }
        $c = [c]::new()
        It 'a method can read a property' {
            $c.GetP() | Should be 1
            $c.p | Should be 1
        }
        It 'a method can change a property' {
            $c.SetP()
            $c.p | Should be 2
            $c.GetP() | Should be 2
        }
    }
    Context 'parameters' {
        It 'untyped parameters are intuitive' {
            class c {
                $p
                m($arg) { $this.p = $arg }
            }
            $c = [c]::new()
            $c.m( 0x10 )
            $c.p | Should be 16
            $c.p | Should beOfType 'int32'
        }
        It 'coercion occurs on passing argument' {
            class c {
                $p
                m([string]$arg) { $this.p = $arg.GetType() }
            }
            $c = [c]::new()
            $c.m( 0x10 )
            $c.p.Name | Should be 'string'
        }
        It 'default parameter values are not supported' {
            class c {
                $p
                m($arg=1) { $this.p = $arg}
            }
            $c = [c]::new()
            $c.p | Should beNullOrEmpty
            { $c.m() } |
                Should throw 'Cannot find an overload'
        }
        It 'omitting a parameter is not supported' {
            class c { m($arg1,$arg2) {} }
            $c = [c]::new()
            { $c.m(1) } |
                Should throw 'Cannot find an overload'
        }
    }
    Context 'method overloads' {
        It 'discrimates based on number' {
            class c {
                $p
                m() {$this.p = 'no args' }
                m($arg) { $this.p = 'one arg' }
                m($arg1,$arg2) { $this.p = 'two args' }
            }
            $c = [c]::new()
            $c.m()
            $c.p | Should be 'no args'
            $c.m(1)
            $c.p | Should be 'one arg'
            $c.m(1,2)
            $c.p | Should be 'two args'
        }
        It 'discriminates based on type' {
            class c {
                $p
                m([int]$arg) { $this.p = 'int' }
                m([double]$arg) { $this.p = 'double' }
                m([string]$arg) { $this.p = 'string' }
            }
            $c = [c]::new()
            $c.m(1)
            $c.p | Should be 'int'
            $c.m(1.0)
            $c.p | Should be 'double'
            $c.m('1')
            $c.p | Should be 'string'
        }
        It 'selects more specific type' {
            class c {
                $p
                m([object]$arg) { $this.p = 'object' }
                m([string]$arg) { $this.p = 'string' }
            }
            $c = [c]::new()
            $c.m('string')
            $c.p | Should be 'string'
            $c.m(1.0)
            $c.p | Should be 'object'
        }
    }
    Context 'static methods' {
        class a {
            $p
            static [object]sm() {return 'sm'}
            static sm([a]$arg) { $arg.p = 'value set by sm' }
        }
        It 'static methods are allowed' {
            [a]::sm() | Should be 'sm'
        }
        It 'static method can accept its own type' {
            $a = [a]::new()
            [a]::sm($a)
            $a.p | Should be 'value set by sm'
        }
    }
}
Describe 'naming' {
    Context 'class names' {
        $characters = @{
            Allowed = 'a_'
            NotAllowed = '`-=~!@#$%^&*()+[]\|;''",./<>?'
            Special = ':{}'
        }
        foreach ( $char in $characters.Allowed.GetEnumerator() )
        {
            It "$char is allowed" {
                iex "class a$($char)b {}"
            }
        }
        foreach ( $char in $characters.NotAllowed.GetEnumerator() )
        {
            It "$char is not allowed" {
                { iex "class a$($char)b {}" } |
                    Should throw "Missing 'class' body in 'class' declaration."
            }
        }
        foreach ( $length in 255,256,511,512,1000,1005,1006,1007)
        {
            It "$length character names are allowed" {
                $name = 'a'*$length
                $name.Length | Should be $length
                iex "class $name {}"
            }
        }
        foreach ( $length in 1008,1009,1022,1023,1024,2047,4095 )
        {
            It "$length character names are too long" {
                $name = 'a'*$length
                $name.Length | Should be $length
                { iex "class $name {}" } |
                    Should throw 'Type name was too long'
            }
        }
        foreach ( $name in 'function', 'configuration','class','static','hidden' )
        {
            It "name $name is allowed" {
                iex "class $name {}"
                iex "`$c = [$name]::new()"
            }
        }
    }
}
Describe 'inheritance' {
    Context 'plain' {
        class a {
            $p
            [object]m() { return 'm' }
        }
        class b : a {}
        $b = [b]::new()
        It 'type of subclass is as expected' {
            $r = $b.GetType()
            $r.Name | Should be 'b'
        }
        It 'type of subclass mentions base class' {
            $r = $b.GetType()
            $r.BaseType.Name | Should be 'a'
        }
        It 'inherits method of parent class' {
            $r = $b.m()
            $r | Should be 'm'
        }
        It 'inherits property of parent class' {
            $b.p = 'value'
            $b.p | Should be 'value'
        }
    }
    It 'inheriting from two parents is not allowed' {
        $guid = [guid]::NewGuid().Guid.Replace('-','')
        class a {}
        class b {}
        { iex "class c$guid : a,b {}" } |
            Should throw 'Interface name expected'
    }
    It 'multiple generations of inheritance is allowed' {
        class a {}
        class b : a {}
        class c : b {}
    }
    Context 'grandparent' {
        class a     { $a; [object]ma() { return 'a' } }
        class b : a { $b; [object]mb() { return 'b' } }
        class c : b { $c; [object]mc() { return 'c' } }
        $c = [c]::new()
        $t = $c.GetType()
        It 'type of grandchild class is as expected' {
            $t.Name | Should be 'c'
        }
        It 'base type of grandchild class is parent' {
            $t.BaseType.Name | Should be 'b'
        }
        It 'can walk the type tree up to grandparent' {
            $t.BaseType.BaseType.Name | Should be 'a'
        }
        It 'inherits method of parent class' {
            $r = $c.mb()
            $r | Should be 'b'
        }
        It 'inherits method of grandparent class' {
            $r = $c.ma()
            $r | Should be 'a'
        }
        It 'inherits property of parent class' {
            $c.b = 'value'
            $c.b | Should be 'value'
        }
        It 'inherits property of grandparent class' {
            $c.a = 'value'
            $c.a | Should be 'value'
        }
    }
}
Describe 'overrides' {
    Context 'override base class method' {
        class a {
            [object]m() { return 'a' }
            [object]m($arg) { return 'a arg' }
            [object]m([string]$arg) {return 'a string arg' }
        }
        class b : a {
            [object]m() { return 'b' }
        }
        $b = [b]::new()
        It 'simple overriding of base class method works as expected' {
            $b.m() | Should be 'b'
        }
        It 'parent method overload is called for differing number of arguments' {
            $b.m(1) | Should be 'a arg'
        }
        It 'parent method overload is called for differing argument type' {
            $b.m('string') | Should be 'a string arg'
        }
    }
    Context 'call base class method from overridden implementation' {
        class a {
            [object]m() { return 'a' }
        }
        class b : a {
            [object]m() { return ([a]$this).m()+'b' }
        }
        $b = [b]::new()
        It 'child method calls base method' {
            $b.m() | Should be 'ab'
        }
    }
    Context 'override base class property' {
        class a {
            [string] $p1 = $($this.p2 = 'p2val' );
            [string] $p2
        }
        class b :a {
            [hashtable] $p1
        }
        It 'child type overrides base class type' {
            $c = [b]::new()
            $c.p1 = @{}
            $c.p1 | Should beOfTYpe ([hashtable])
        }
        It 'initializer is invoked for property on base class even when it is overridden' {
            $c = [b]::new()
            $c.p2 | Should be 'p2val'
        }
    }
    Context 'override of custom setter and getter using Add-Members' {
        class a {
            hidden $_p = $($this | Add-Member ScriptProperty 'p' {
                # get
                "GetterA $($this._p)"
            } {
                # set
                param ( $arg )
                $this._p = "SetterA $arg"
            })
        }
        class b {
            hidden $_p = $($this | Add-Member ScriptProperty 'p' {
                # get
                "GetterB $($this._p)"
            } {
                # set
                param ( $arg )
                $this._p = "SetterB $arg"
            })
        }
        $c = [b]::new()
        It 'the overridden setter and getter works as expected' {
            $c.p = 'arg value'
            $c.p | Should be 'GetterB SetterB arg value'
        }
    }
}
Describe 'type equality' {
    class a {}
    class b : a {}
    $a = [a]::new()
    $b = [b]::new()
    It '$subClass -is [baseClass]' {
        $b -is [a] | Should be $true
    }
    It '$baseClass -isnot [subClass]' {
        $a -isnot [b] | Should be $true
    }
}
Describe 'constructors' {
    Context 'plain' {
        class a {
            $p
            a() {$this.p = 'a'}
        }
        class b {
            $p = 'init'
            b() {$this.p = $this.p * 2}
        }
        It 'new() invokes constructor' {
            [a]::new().p | Should be 'a'
        }
        It 'properties are initialized before constructor is run' {
            [b]::new().p | Should be 'initinit'
        }
    }
    Context 'conversion from hashtable - no constructor' {
        class a {
            $p
        }
        It 'populates property' {
            $r = [a]@{p=1}
            $r.p | Should be 1
        }
        It 'empty hashtable' {
            $r = [a]@{}
            $r.p | Should beNullOrEmpty
        }
        It 'extra item throws' {
            { [a]@{q=1} } |
                Should throw 'property was not found'
        }
    }
    Context 'conversion from hashtable - constructor' {
        class a {
            $p
            a ($s) { $this.p = $s }
        }
        It 'hashtable is constructor argument' {
            $r = [a]@{p=1}
            $r.p | Should beOfType ([hashtable])
        }
    }
    Context 'conversion from array - no constructor' {
        class a {
            $p
        }
        It 'throw' {
            { [a]@(1) } |
                Should throw 'Cannot convert'
        }
    }
    Context 'conversion from array - single-parameter constructor' {
        class a {
            $p
            a ($a)
            {
                $this.p = $a
            }
        }
        It 'elements are arguments - single element' {
            $r = [a]@(1)
            $r.p | Should be 1
        }
        It 'elements are arguments - multiple elements' {
            $r = [a]@(1,2)
            $r.p | Should be 1,2
        }
    }
    class b { $p }
    Context 'conversion from base class - no constructor' {
        class c : b { $q }
        It 'throws' {
            { [c]([b]::new()) } |
                Should throw 'Cannot convert'
        }
    }
    Context 'conversion from base class - conversion constructor' {
        class c : b {
            $q
            c ([b]$b) { $this.p = $b.p }
        }
        It 'converts' {
            $r = [c]([b]@{p=1})
            $r | Should beOfType ([c])
            $r.p | Should be 1
        }
    }
    Context 'explicit conversion - single paramter' {
        class a {
            $p
            a ([int]$i) { $this.p = $i }
            a ([string]$s) { $this.p = $s }
        }
        It 'converts to exact type match' {
            $r = [a]1
            $r.p | Should beOfType ([int])
            $r.p | Should be 1

            $r = [a]'1'
            $r.p | Should beOfType ([string])
            $r.p | Should be '1'
        }
    }
    Context 'explicit conversion - second parameter with default' {
        class a {
            $p
            $q
            a ([int]$i,$b=2)
            {
                $this.p = $i
                $this.q = $b
            }
        }
        It 'throws' {
            { [a]1 } | Should throw 'Cannot convert'
        }
    }
    Context 'static constructor' {
        $guid = [guid]::NewGuid().Guid.Replace('-','')
        class a {
            static $sp
            static a() { [a]::sp = 'set by static a()' }
        }
        class b {
            static $sp = 'init'
            static b() { [b]::sp = [b]::sp*2 }
        }
        It 'static default constructors are supported' {
            [a]::sp | Should be 'set by static a()'
        }
        It 'static constructors with parameters are not supported' {
            { iex "class b$guid { static b$guid(`$arg) {} }" } |
                Should throw 'A static constructor cannot have any parameters'
        }
        It 'static properties are initialized before static constructors are called' {
            [b]::sp | Should be 'initinit'
        }
    }
    Context 'mixed static and non-static properties and constructors' {
        class a {
            static $sp = 'sp init'
            $p = 'p init'
            static a() { [a]::sp = [a]::sp * 2}
            a() { $this.p = $this.p + [a]::sp }
        }
        It 'initialize static properties, run static constructor, initialize non-static properties, run non-static constructor' {
            [a]::new().p | Should be 'p initsp initsp init'
        }
    }
    Context 'call base class constructor' {
        $guid = [guid]::NewGuid().Guid.Replace('-','')
        class a {
            $p
            a($arg) { $this.p = $arg }
        }
        class b : a {
            b() : base('b arg') {}
            b($arg) : base($arg) {}
        }
        class c : a {
            c() : base ('c arg') { $this.p = $this.p * 2 }
        }
        class d : b {
            d() : base() {}
        }
        class e : b {}
        class f : b {
            f() {}
        }
        class g : a {
            g() {}
        }
        It 'calls base class constructor with literal from subclass' {
            [b]::new().p | Should be 'b arg'
        }
        It 'calls base class constructor with argument from subclass constructor' {
            [b]::new('passed arg').p | Should be 'passed arg'
        }
        It 'calls base class constructor prior to subclass constructor' {
            [c]::new().p | Should be 'c argc arg'
        }
        It 'base refers to immediate ancestor' {
            [d]::new().p | Should be 'b arg'
        }
        It 'omitting constructor automatically calls base class constructor' {
            [e]::new().p | Should be 'b arg'
        }
        It 'omitting constructor where base class has no default constructor causes error' {
            { iex "class h$guid : a {}" } |
                Should throw "Base class 'a' does not contain a parameterless constructor."
        }
        It 'if a base class has a default constructor it is called automatically before the subclass constructor' {
            [f]::new().p | Should be 'b arg'
        }
        It 'if the subclass default constructor doesn''t mention a base class constructor, the base class must implement a default constructor' {
            { [g]::new().p } |
                Should throw 'Cannot find an overload for "new" and the argument count: "0"'
            [f]::new().p | Should be 'b arg'
        }
    }
}
Describe 'interfaces' {
    Context 'interfaces' {
        $guid = [guid]::NewGuid().Guid.Replace('-','')
        It 'declaring an interface is a contract that has to be implemented' {
            {iex "class a$guid : System.IComparable {}" } |
                Should throw "Method 'CompareTo' in type" # ...does not have an implementation
        }
        It 'the implementation of interface method must have correct signature' {
            { iex "class a$guid : System.IComparable { CompareTo() {} }" } |
                Should throw "Method 'CompareTo' in type"
            class a : System.IComparable {
                [int] CompareTo([object] $obj) { return 0 }
            }
        }
        It 'the interface can be used' {
            class a : System.IComparable {
                [int] CompareTo([object] $obj) { return 1 }
            }
            $a1 = [a]::new()
            $a2 = [a]::new()

            $a1 -gt $a2 | Should be $true
            $a1 -le $a2 | Should be $false
            $a2 -gt $a1 | Should be $true
        }
    }
}
Describe 'equality' {
    Context 'basic class' {
        class a { $p }
        It 'equating objects with equal properties returns false' {
            $r = [a]@{p=1} -eq [a]@{p=1}
            $r | Should be $false
        }
    }
    Context '.Equals()' {
        class a {
            $p
            [bool] Equals($other) { return $other.p -eq $this.p }
        }
        It 'equating objects with <d> properties returns <r>' -TestCases @(
            @{d = 'unequal';v=1,1;r=$true}
            @{d = 'equal'  ;v=1,2;r=$false}
        ) {
            param($d,$v,$r)
            $r = [a]@{p=$v[0]} -eq [a]@{p=$v[1]}
            $r | Should be $r
        }
    }
}
