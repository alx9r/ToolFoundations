Import-Module ToolFoundations -Force

Describe Out-Collection {
    Function Raw {
        [CmdletBinding()]
        param([parameter(position=1)]$InputObject)
        process{$InputObject}
    }
    Function RawReturn {
        [CmdletBinding()]
        param([parameter(position=1)]$InputObject)
        process{ return $InputObject}
    }
    Function UsingOutCollection {
        [CmdletBinding()]
        param([parameter(position=1)]$InputObject)
        process{ Out-Collection $InputObject}
    }
    Function UsingOutCollectionReturn {
        [CmdletBinding()]
        param([parameter(position=1)]$InputObject)
        process{ return Out-Collection $InputObject }
    }
    Function UsingOutCollectionAllowNullorEmpty {
        [CmdletBinding()]
        param([parameter(position=1)]$InputObject)
        process{ return Out-Collection $InputObject -AllowNullOrEmpty }
    }
    Function TwoOutputsUsingOutCollection {
        [CmdletBinding()]
        param([parameter(position=1)]$InputObject)
        process
        {
            Out-Collection $InputObject
            Out-Collection $InputObject
        }
    }
    Function TwoOutputsRaw {
        [CmdletBinding()]
        param([parameter(position=1)]$InputObject)
        process
        {
            $InputObject
            $InputObject
        }
    }
    Context 'raw versus Out-Collection examples' {
        It 'normally unrolls a 1x1 array.' {
            $o = Raw @(10)
            $o -is [int] | Should be $true
        }
        It 'preserves a 1x1 array.' {
            $o = UsingOutCollection @(10)
            $o.Count        | Should be 1
            $o -is [Array]  | Should be $true
            $o[0] -is [int] | Should be $true
            $o[0]           | Should be 10
        }
        It 'normally unrolls an ArrayList.' {
            $o = Raw ([System.Collections.ArrayList]@(10,20))
            $o -is [Array] | Should be $true
        }
        It 'preserves ArrayList.' {
            $o = UsingOutCollection ([System.Collections.ArrayList]@(10,20))
            $o -is [System.Collections.ArrayList] | Should be $true
        }
        It 'empty stack normally evaluates to true.' {
            $o = New-Object System.Collections.Stack
            [bool]$o | Should be $true
        }
        It 'empty stack normally doesn''t make it through the pipeline...' {
            $o = Raw (New-Object System.Collections.Stack)
            $null -eq $o | Should be $true
        }
        It '...even when return is used.' {
            $o = RawReturn (New-Object System.Collections.Stack)
            $null -eq $o | Should be $true
        }
        It 'empty stack survives when wrapped in sacrificial wrapper.' {
            $o = Raw (,(New-Object System.Collections.Stack))
            $o.GetType() | Should match 'stack'
        }
        It 'converts empty stack to null...' {
            $o = UsingOutCollection (New-Object System.Collections.Stack)
            $null -eq $o | Should be $true
        }
        It '...but not when AllowNullOrEmpty' {
            $o = UsingOutCollectionAllowNullorEmpty (New-Object System.Collections.Stack)
            $null -eq $o | Should be $false
        }
        It 'normally linearizes square array.' {
            $o = TwoOutputsRaw @(10,'ten')
            $o.Count | Should be 4
        }
        It 'preserves array squareness.' {
            $o = TwoOutputsUsingOutCollection @(10,'ten')
            $o.Count    | Should be 2
            $o[0].Count | Should be 2
            $o[1].Count | Should be 2
        }
        It 'normally outputs null for 1x1 array containing null item.' {
            $o = Raw @($null)

            $null -eq $o | Should be $true
        }
        It 'preserves 1x1 array containing null item.' {
            $o = UsingOutCollection @($null)

            $o.Count | Should be 1
            $null -eq $o[0] | Should be $true
        }
        It 'normally outputs null for 1x1 array containing null item. (return)' {
            $o = RawReturn @($null)

            $null -eq $o | Should be $true
        }
        It 'preserves 1x1 array containing null item only in PowerShell 3+. (return)' {
            $o = UsingOutCollectionReturn @($null)

            if ( $PSVersionTable.PSVersion.Major -le 2 )
            {
                $null -eq $o | Should be $true
            }
            else
            {
                $o.Count | Should be 1
                $null -eq $o[0] | Should be $true
            }
        }
    }
    Context "powershell objects" {
        It "does not accept pipeline input (that would be insane)." {
            (gcm Out-Collection).Parameters.InputObject.Attributes[0].ValueFromPipeline |
                Should be $false
        }
        It "passes through objects that are not ienumerable." {
            $obj = New-Object PSObject -Property @{StringProp='StringLiteral'}
            (Out-Collection $obj) | Should be $obj
        }
        It "emits an empty array for an empty array." {
            $o = Out-Collection @()
            $o | Should BeNullOrEmpty
            $o.Count | Should be 0
            $o -is [System.Array] | Should be $true
        }
        It 'normally empty hashtables evaluate to true.' {
            [bool]@{} | Should be $true
        }
        It 'emits value for empty hashtable that evaluates to false.' {
            [bool](Out-Collection @{}) | Should be $false
        }
        It 'emits null for an empty hashtable...' {
            $r = Out-Collection @{}
            $null -eq $r | Should be $true
        }
        It '...except when AllowNullOrEmpty' {
            $r = UsingOutCollectionAllowNullorEmpty @{}
            $null -eq $r | Should be $false
        }
        It "emits hashtable for a non-empty hashtable." {
            $h = @{a=20}
            (Out-Collection $h) | Should be $h
        }
        It "emits a 1x1 array for a 1x1 array." {
            $o = Out-Collection @(10)
            $o.Count | Should be 1
            $o -is [System.Array] | Should be $true
            $o[0] | Should be 10
        }
        It "emits a 2x1 array for a 2x1 array." {
            $o = Out-Collection @(10,20)
            $o.Count | Should be 2
            $o -is [System.Array] | Should be $true
            $o[0] | Should be 10
            $o[1] | Should be 20
        }
        It "emits a 1x2 array for a 1x2 array." {
            $o = Out-Collection @(,(10,20))
            $o.Count | Should be 1
            $o -is [System.Array] | Should be $true
            $o[0].Count | Should be 2
            $o[0] -is [System.Array] | Should be $true
            $o[0][0] | Should be 10
            $o[0][1] | Should be 20
        }
        It "emits a 2x2 array for a 2x2 array." {
            $o = Out-Collection @((10,20),(30,40))
            $o.Count | Should be 2
            $o -is [System.Array] | Should be $true
            $o[0].Count | Should be 2
            $o[0] -is [System.Array] | Should be $true
            $o[1].Count | Should be 2
            $o[1] -is [System.Array] | Should be $true
            $o[0][0] | Should be 10
            $o[0][1] | Should be 20
            $o[1][0] | Should be 30
            $o[1][1] | Should be 40
        }
    }
}
Describe 'Out-Collection (dotnet collections)' {
    Function UsingOutCollection {
        [CmdletBinding()]
        param([parameter(position=1)]$InputObject)
        process{ Out-Collection $InputObject}
    }
    Function UsingOutCollectionReturn {
        [CmdletBinding()]
        param([parameter(position=1)]$InputObject)
        process{ return Out-Collection $InputObject }
    }
    Function UsingOutCollectionAllowNullorEmpty {
        [CmdletBinding()]
        param([parameter(position=1)]$InputObject)
        process{ return Out-Collection $InputObject -AllowNullOrEmpty }
    }
    Function TwoOutputsUsingOutCollection {
        [CmdletBinding()]
        param([parameter(position=1)]$InputObject)
        process
        {
            Out-Collection $InputObject
            Out-Collection $InputObject
        }
    }

    $miObjects =
        @(1,2,3),
        @{a=1;b=2;c=3},
        (New-Object string 'TenTwentyThirty'),
        (& {
            $l = New-Object "System.Collections.Generic.List``1[System.int32]"
            10,20,30 | % {$l.Add($_)}
            $l
        }),
        [System.Collections.ArrayList]@(10,20,30),
        (New-Object System.Collections.BitArray 16),
        [System.Collections.Hashtable]@{ten=10;twenty=20;thirty=30},
        [System.Collections.Queue]@(10,20,30),
        [System.Collections.SortedList]@{ten=10;twenty=20;thirty=30},
        [System.Collections.Stack]@(10,20,30),
        (& {
            $d = New-Object "System.Collections.Generic.Dictionary``2[System.String,System.int32]"
            ('ten',10),('twenty',20),('thirty',30) | % {$d.Add($_[0],$_[1])}
            $d
        })

    $siObjects =
        @(1),
        @{a=1},
        (New-Object string 't'),
        (& {
            $l = New-Object "System.Collections.Generic.List``1[System.int32]"
            10 | % {$l.Add($_)}
            $l
        }),
        [System.Collections.ArrayList]@(10),
        (New-Object System.Collections.BitArray 1),
        [System.Collections.Hashtable]@{ten=10},
        [System.Collections.Queue]@(10),
        [System.Collections.SortedList]@{ten=10},
        [System.Collections.Stack]@(10),
        (& {
            $d = New-Object "System.Collections.Generic.Dictionary``2[System.String,System.int32]"
            ,('ten',10) | % {$d.Add($_[0],$_[1])}
            $d
        })

    $emptyObjects =
        @{},
        [string]::Empty,
        (New-Object "System.Collections.Generic.List``1[System.int32]"),
        (New-Object System.Collections.ArrayList),
        (New-Object System.Collections.BitArray 0),
        (New-Object System.Collections.Hashtable),
        (New-Object System.Collections.Queue),
        (New-Object System.Collections.SortedList),
        (New-Object System.Collections.Stack),
        (New-Object "System.Collections.Generic.Dictionary``2[System.String,System.int32]")

    Context 'collections containing multiple items' {
        foreach ( $c in $miObjects )
        {
            It "preserves collection $($c.GetType().FullName)" {
                $r = UsingOutCollection $c
                $c.GetType().BaseType.FullName | Should be $r.GetType().BaseType.FullName
                $c.GetType().FullName          | Should be $r.GetType().FullName
                $c.Count                       | Should be $r.Count
            }
            It "doesn''t linearize two outputs for $($c.GetType().FullName)" {
                $r = TwoOutputsUsingOutCollection $c
                $r.Count | Should be 2
            }
        }
    }
    Context 'collections containing single items' {
        foreach ( $c in $siObjects )
        {
            It "preserves collection $($c.GetType().FullName)" {
                $r = UsingOutCollection $c
                $c.GetType().BaseType.FullName | Should be $r.GetType().BaseType.FullName
                $c.GetType().FullName          | Should be $r.GetType().FullName
                $c.Count                       | Should be $r.Count
            }
        }
    }
    Context 'collections containing no items' {
        foreach ( $c in $emptyObjects )
        {
            It "emits null for collection $($c.GetType().FullName)" {
                $r = UsingOutCollection $c
                $null -eq $r | Should be $true
            }
            It "...except when AllowNullOrEmpty." {
                $r = UsingOutCollectionAllowNullorEmpty $c
                $null -eq $r | Should be $false
            }
        }
    }
}
Describe 'Out-Collection (XML)' {
    Context 'dotnet XML' {
        Mock Write-Warning -Verifiable
        $doc = [xml]'<doc><sometags><tag/><tag/></sometags><sometags><tag/><tag/></sometags></doc>'
        It 'preserves XML Element containing a single element.' {
            $single = $doc.doc.sometags[0]

            $out = Out-Collection $single
            $out | Should BeOfType ([System.Xml.XmlElement])
            $out.GetHashCode() | Should be $single.GetHashCode()
        }
        It 'preserves XML Element containing multiple elements.' {
            $multiple = $doc.doc.sometags
            $multiple.Count | Should be 2

            $out = Out-Collection $multiple
            $out.GetHashCode() | Should be $multiple.GetHashCode()
            $out | Should BeOfType ([System.Xml.XmlElement])
        }
        It 'does not raise warning.' {
            Assert-MockCalled Write-Warning -Times 0
        }
    }
}

Describe 'New-GenericObject' {
    Context '.Net collection of .Net objects' {
        It 'create dictionary using generics' {
            $r= New-GenericObject 'System.Collections.Generic.Dictionary' ([System.String]),([System.Int32])
            $r.GetType() | Should match 'System.Collections.Generic.Dictionary'
        }
        It 'create dictionary using a type in the Automation namespace' {
            $r = New-GenericObject 'System.Collections.Generic.Dictionary' 'System.String','System.Management.Automation.CommandInfo'
            $r.GetType() | Should match 'System.Collections.Generic.Dictionary'
        }
    }
    if ( $PSVersionTable.PSVersion -ge '5.0' )
    {
        Context '.Net collection of PowerShell Class objects' {
            iex 'class a {$p}'
            $h = @{}
            It 'create dictionary using a PowerShell class' {
                $h.a = New-GenericObject 'System.Collections.Generic.Dictionary' 'System.String',([a])
            }
            It 'add an item' {
                $c = [a]::new()
                $c.p = 'item1'
                $h.a.Add('item1',$c)
            }
            It 'retrieve the item' {
                $h.a.item1.p | Should be 'item1'
            }
        }
    }
}
