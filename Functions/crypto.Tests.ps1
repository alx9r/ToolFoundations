if ( $PSVersionTable.PSVersion -lt '3.0' )
{
    return
}

Import-Module ToolFoundations -Force

Describe Get-StringHash {
    It 'outputs empty string for $null' {
        $r = $null | Get-StringHash
        $r -eq [string]::Empty | Should be $true
    }
    It 'outputs empty string for empty string' {
        $r = [string]::Empty | Get-StringHash
        $r -eq [string]::Empty | Should be $true
    }
    Context 'produces correct hash' {
        $cases = @(
            # Input            Output
            @('2015-12-31',    '88C70C62B60E24E699C5EF143097BA0AE291028E047AFE02DBBC0C84EB713BF2'),
            @('3182feb2',      'E6E6E7771EFBAB77C07078DBD2757E5DF77F41D256CFFDC1210868A97C7F417A' )
        )
        foreach ($case in $cases) {
            $in = $case[0]
            $out = $case[1]
            It "Input: $in" {
                $r = $in | Get-StringHash
                $r | Should be $out
            }
        }
    }
    Context 'produces correct hash (base64)' {
        $cases = @(
            # Input            Output
            @('2015-12-31',    'iMcMYrYOJOaZxe8UMJe6CuKRAo4Eev4C27wMhOtxO/I='),
            @('3182feb2',      '5ubndx77q3fAcHjb0nV+Xfd/QdJWz/3BIQhoqXx/QXo=' )
        )
        foreach ($case in $cases) {
            $in = $case[0]
            $out = $case[1]
            It "Input: $in" {
                $r = $in | Get-StringHash -OutputEncoding base64
                $r | Should be $out
            }
        }
    }
    Context 'produces correct hash (MD5)' {
        $cases = @(
            # Input            Output
            @('2015-12-31',    '3CD65455CC6F334EC9D8199520886136'),
            @('3182feb2',      '1C62A2CDD714ADEBA8FAF75FCACFA9B8' )
        )
        foreach ($case in $cases) {
            $in = $case[0]
            $out = $case[1]
            It "Input: $in" {
                $r = $in | Get-StringHash -Algorithm (New-Object System.Security.Cryptography.MD5CryptoServiceProvider)
                $r | Should be $out
            }
        }
    }
}
