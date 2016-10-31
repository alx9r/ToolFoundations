$records = @{}
Describe '.Net collection' {
    It 'create dictionary using generics' {
        $records.Int32 = New-Object "System.Collections.Generic.Dictionary``2[System.String,int32]"
    }
    It 'create dictionary using a type in the Automation namespace' {
        $records.CommandInfo = New-Object "System.Collections.Generic.Dictionary``2[System.String,System.Management.Automation.CommandInfo]"
    }
}

if ( $PSVersionTable.PSVersion -ge '5.0' )
{
    . "$($PSCommandPath | Split-Path -Parent)\collectionTests.ps1"
}
