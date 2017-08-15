if ( $PSVersionTable.PSVersion -lt 5.0.0 )
{
    return
}

# The .Net type must be added before the file that uses it
# is parsed.
Add-Type "public enum Triple_b3f43f68 { one, two, three }"
Add-Type "public class Widget_b3f43f68 { public int i; }"

. "$PSScriptRoot\dotnetMemberTests.ps1"
