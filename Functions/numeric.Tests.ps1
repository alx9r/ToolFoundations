Import-Module ToolFoundations -Force

Describe Test-NumericType {
    $tests = @(
        @([int32],$true),
        @([uint32],$true),
        @([int16],$true),
        @([uint16],$true),
        @([byte],$true),
        @([sbyte],$true),
        @([double],$true),
        @([float],$true),
        @([decimal],$true),
        @([string],$false),
        @([datetime],$false)
        @([hashtable],$false),
        @([array],$false),
        @([System.Collections.ArrayList],$false),
        @([System.Collections.BitArray],$false),
        @([System.Collections.Queue],$false),
        @([System.Collections.Stack],$false)
    )
    foreach ( $case in $tests )
    {
        It "Returns $($case[1]) for $($case[0].Name)" {
            $r = $case[0] | Test-NumericType
            $r | Should be $case[1]
        }
    }
}
