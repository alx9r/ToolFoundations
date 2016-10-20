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
            $r = Get-Member -InputObject $c -MemberType Property
            $r.Definition | Should match 'get'
        }
        It 'the property has a setter' {
            $r = Get-Member -InputObject $c -MemberType Property
            $r.Definition | Should match 'set'
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
            $r = Get-Member -InputObject $c -MemberType Property -Force
            $r.Definition | Should match 'get'
        }
        It 'the property has a setter' {
            $r = Get-Member -InputObject $c -MemberType Property -Force
            $r.Definition | Should match 'set'
        }
        It 'the property can be set as usual' {
            $c.p = 'value'
        }
        It 'the property can be retrieved as usual' {
            $c.p | Should be 'value'
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
    Context 'classes in modules' {
        # http://stackoverflow.com/q/31051103/1404637
        $guid = [guid]::NewGuid().Guid
        $module = New-Module -Name "Module-$guid" {
            class c {}
            function New-CObject { return [c]::new() }
            $newC = [c]::new()
            Export-ModuleMember -Variable * -Function *
        }
        $module | Import-Module
        It 'class is not available outside module by default' {
            { [c]::new() } |
                Should throw 'Unable to find type'
        }
        It 'a function in the module can return an instance of the class' {
            $r = New-CObject
            $r.GetType().Name | Should be 'c'
        }
        It 'a variable exported from a module can be an instance of the class' {
            $newC.GetType().Name | Should be 'c'
        }
        It 'class is available outside module after using statement in dot-sourced script' {
            $r = . "$($PSCommandPath | Split-Path -Parent)\..\Resources\initiateUsingModuleTest.ps1"
            $r.GetType().Name | Should be 'c'
        }
        It 'class is not available outside module after using statement invoked with iex when new() invoked without iex' {
            $path = "$($PSCommandPath | Split-Path -Parent)\..\Resources\classModuleStub.psm1"
            Import-Module $path
            iex "using module $path"
            { [c]::new() } |
                Should throw 'Unable to find type'
        }
        It 'class is available outside module after using statement invoked with iex when new() invoked with iex' {
            $path = "$($PSCommandPath | Split-Path -Parent)\..\Resources\classModuleStub.psm1"
            Import-Module $path
            iex "using module $path"
            $r = iex '[c]::new()'
            $r.GetType().Name | Should be 'c'
        }
    }
    Context 'using statement' {
        It 'using statement at beginning of scriptblock is not allowed' {
            # uncommenting the following line creates a ParseError
            #{ using module "ToolFoundations"; } |
            #    Should throw "'using' statement must appear before"
        }
        It 'using statement using iex is allowed' {
            iex 'using module "ToolFoundations";'
        }
        It 'using statement is not allowed for modules not in PSModulePath...' {
            Import-Module "$($PSCommandPath | Split-Path -Parent)\..\Resources\classModuleStub.psm1" -Force
            { iex 'using module classModuleStub' } |
                Should throw 'Could not find the module'
        }
        It '...unless using statement uses their full file path.' {
            $path = "$($PSCommandPath | Split-Path -Parent)\..\Resources\classModuleStub.psm1"
            Import-Module $path
            iex "using module $path"
        }
        It 'using statement at beginning of scriptblock using iex is not allowed' {
            { iex '{ using module "ToolFoundations"; }' } |
                Should throw "A 'using' statement must appear before"
        }
        It 'using statement at beginning of scriptblock not bound to any module is not allowed' {
            # uncommenting the following line creates a ParseError
            #{ [scriptblock]::Create( { using module "ToolFoundations"; } ) } |
            #    Should throw "'using' statement must appear before"
        }
        It 'using statement at beginning of scriptblock not bound to any module using iex is not allowed' {
            { [scriptblock]::Create('{ using module "ToolFoundations"; }') } |
                Should throw "'using' statement must appear before"
        }
        It 'using statement at beginning of scriptblock bound to a module is not allowed (1)' {
            { New-Module -ScriptBlock (iex '{ using module "ToolFoundations"; }') } |
                Should throw "'using' statement must appear before"
        }
        It 'using statement at beginning of scriptblock bound to a module is not allowed (2)' {
            { New-Module -ScriptBlock ([scriptblock]::Create('{ using module "ToolFoundations"; }')) } |
                Should throw "'using' statement must appear before"
        }
        It 'using statement at beginning of scriptblock bound to a module is not allowed (3)' {
            { New-Module -ScriptBlock (iex '[scriptblock]::Create({ using module "ToolFoundations"; })') } |
                Should throw "'using' statement must appear before"
        }
        It 'using statement at beginning of scriptblock bound to a module is not allowed (4)' {
            { iex 'New-Module -ScriptBlock { using module "ToolFoundations"; }' } |
                Should throw "'using' statement must appear before"
        }
        It 'using statement at beginning of dot-sourced script is allowed' {
            . "$($PSCommandPath | Split-Path -Parent)\..\Resources\usingModuleTest.ps1"
        }
        It 'using statement at beginning of script invoked using call operator is allowed' {
            & "$($PSCommandPath | Split-Path -Parent)\..\Resources\usingModuleTest.ps1"
        }
    }
    Context 'inheritance' {
        class a {
            $p
            [object]m() { return 'm' }
        }
        class b : a {}
        $b = [b]::new()
        It 'type of derived class is as expected' {
            $r = $b.GetType()
            $r.Name | Should be 'b'
        }
        It 'type of derived class mentions base class' {
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
        class a {}
        class b {}
        { iex 'class c : a,b {}' } |
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
    Context 'override base class method' {
        class a {
            [object]m() { return 'a' }
            [object]m($arg) { return 'a arg' }
            [object]m([string]$arg) {return 'a string arg' }
        }
        class b : a {
            [object]m() { return 'b' }
        }
        $c = [b]::new()
        It 'simple overriding of base class method works as expected' {
            $c.m() | Should be 'b'
        }
        It 'parent method overload is called for differing number of arguments' {
            $c.m(1) | Should be 'a arg'
        }
        It 'parent method overload is called for differing argument type' {
            $c.m('string') | Should be 'a string arg'
        }
    }
    Context 'static method' {}
    Context 'interfaces' {}
    Context 'constructors' {}
    Context 'call base class constructor' {}
    Context 'call base class method' {}
    Context 'hide non-virtual methods' {}
}
