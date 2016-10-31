Describe '.Net collection with PowerShell classes' {
    Context 'PowerShell Class' {
        class a {$p}
        It 'create dictionary using a PowerShell class' {
            $records.a = New-Object "System.Collections.Generic.Dictionary``2[System.String,a]"
        }
        It 'add an item' {
            $c = [a]::new()
            $c.p = 'item1'
            $records.a.Add('item1',$c)
        }
        It 'retrieve the item' {
            $c =$records.a.item1
            $c.p | Should be 'item1'
        }
    }
}
