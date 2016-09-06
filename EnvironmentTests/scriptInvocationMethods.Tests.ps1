<#
This file demonstrates how to detect whether a test script was invoked
using by Pester (ie. using Invoke-Pester) or directly  (ie. by
pressing F5 in ISE).
#>

$h = @{}
$h.DirectlyInvokedScript = -not [bool]$MyInvocation.Line
$h.PesterInvokedScript = $MyInvocation.Line -match '&\ \$Path\ @Parameters\ @Arguments'

Describe 'Invocation' {
    It "MyInvocation.Line: $($h.MyInvocation.Line)" {}
    It "DirectlyInvokedScript: $($h.DirectlyInvokedScript)" {
        # This is true when the script is invoked by pressing F5
        # in ISE.
    }
    It "PesterInvokedScript: $($h.PesterInvokedScript)" {
        # This is true when the test script is invoked by a call
        # to Invoke-Pester.
    }
}
