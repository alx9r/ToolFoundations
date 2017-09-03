Import-Module ToolFoundations -Force

InModuleScope ToolFoundations {

Describe New-Psm1File {
    Mock Get-TempPsm1Path { 'path' }-Verifiable
    Mock Set-Content -Verifiable
    It 'returns path' {
        $r = New-Psm1File name {'scriptblock'}
        $r | Should be 'path'
    }
    It 'invokes commands' {
        Assert-MockCalled Get-TempPsm1Path 1 {
            $Name -eq 'name'
        }
        Assert-MockCalled Set-Content 1 {
            $Value -eq "'scriptblock'" -and
            $Path -eq 'path'
        }
    }
}

Describe New-Psm1Module {
    Mock New-Psm1File {'path'} -Verifiable
    Mock Import-Module { 'module info' } -Verifiable
    It 'returns module info' {
        $r = New-Psm1Module name {'scriptblock'} -ArgumentList 'args'
        $r | Should be 'module info'
    }
    It 'invokes commands' {
        Assert-MockCalled New-Psm1File 1 {
            [string]$Scriptblock -eq "'scriptblock'"# -and
            $Name -eq 'name'
        }
        Assert-MockCalled Import-Module 1 {
            $Name -eq 'path' -and
            $ArgumentList -eq 'args' -and
            $PassThru
        }
    }
}
}
