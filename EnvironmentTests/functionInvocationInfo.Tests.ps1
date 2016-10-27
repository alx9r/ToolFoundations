$h = @{}
$h.DirectlyInvokedScript = -not [bool]$MyInvocation.Line
$h.PesterInvokedScript = $MyInvocation.Line -match '&\ \$Path\ @Parameters\ @Arguments'

Describe 'PSCmdlet' {
    Context 'functions' {
        function f { $PSCmdlet }
        if ( $h.DirectlyInvokedScript )
        {
            It 'PSCmdlet is empty when script is directly invoked' {
                $r = f
                $r | Should beNullOrEmpty
            }
        }
        if ( $h.PesterInvokedScript )
        {
            It 'PSCmdlet is not empty when script is invoked by Pester' {
                $r = f
                $r | Should not beNullOrEmpty
            }
        }
    }
    Context 'advanced functions' {
        function f {
            [CmdletBinding()]
            param()
            $PSCmdlet
        }
        It 'PSCmdlet is not empty' {
            $r = f
            $r | Should not beNullOrEmpty
        }
        It 'the invokation line is accessible' {
            $r = f
            $r.MyInvocation.Line | Should match '\$r = f'
        }
    }
}
