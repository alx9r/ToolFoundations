Describe 'using modules' {
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
            Import-Module "$($PSCommandPath | Split-Path -Parent)\..\Resources\classModuleStub1.psm1" -Force
            { iex 'using module classModuleStub1' } |
                Should throw 'Could not find the module'
        }
        It '...unless using statement uses their full file path.' {
            $path = "$($PSCommandPath | Split-Path -Parent)\..\Resources\classModuleStub1.psm1"
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
            $r.GetType().Name | Should be 'c1'
        }
    }
}

$path = "$($PSCommandPath | Split-Path -Parent)\..\Resources\classModuleStub2.psm1"
Import-Module $path
iex "using module $path"
Describe 'difference between Pester and script scope' {
    It 'class is not accessible when it is imported and "used" in a Pester scriptblock...' {
        $path = "$($PSCommandPath | Split-Path -Parent)\..\Resources\classModuleStub1.psm1"
        Import-Module $path
        iex "using module $path"
        { [c1]::new() } |
            Should throw 'Unable to find type'
    }
    It 'class is accessible in a Pester scriptblock when it is imported and "used" outside a Pester scriptblock' {
        $r = [c2]::new()
        $r.GetType().Name | Should be 'c2'
    }
}
