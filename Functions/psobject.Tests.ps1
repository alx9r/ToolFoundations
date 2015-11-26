Import-Module ToolFoundations -Force

Describe ConvertTo-HashTable {
    BeforeEach {
        $h = @{
            string  = 'this is a string'
            integer = 12345678
            boolean = $true
        }

        $o = New-Object PSObject -Property $h
    }

    It 'converts an object''s properties to a hash table.' {
        $oh = $o | ConvertTo-Hashtable
        $oh.string | Should be 'this is a string'
        $oh.string -is [string] | Should be $true
        $oh.integer | Should be 12345678
        $oh.integer -is [int32] | Should be $true
        $oh.boolean | Should be $true
        $oh.boolean -is [bool] | Should be $true
    }
    It 'creates an empty hash table when there are no properties.' {
        $eo = New-Object PSObject
        $oh = $eo | ConvertTo-Hashtable
        $oh | Should BeNullOrEmpty
    }
    It 'correctly creates a hash table from PSBoundParameters.' {
        $dict = New-Object -TypeName 'System.Collections.Generic.Dictionary`2[System.String,System.Object]'
        ('p1', 'foo'  ),
        ('p2', 123456 ) |
            % { $dict.Add($_[0],$_[1])       }
        $oh = $dict | ConvertTo-Hashtable
        $oh.p1 | Should be 'foo'
        $oh.p2 | Should be 123456
    }
}
