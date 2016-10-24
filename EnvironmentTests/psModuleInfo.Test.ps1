Get-Module |
    ? {'commandModuleStub1' -eq $_.Name } |
    Remove-Module

$commandModuleStub1Path = "$($PSCommandPath | Split-Path -Parent)\..\Resources\commandModuleStub1.psm1"

Describe 'PSModuleInfo' {
    Context 'Get-Module -ListAvailable' {
        It 'includes ExportedCommands' {
            $r = Get-Module $commandModuleStub1Path -ListAvailable
            $r.ExportedCommands | Should not beNullOrEmpty
        }
        It 'but the commands show no parameters' {
            $r = Get-Module $commandModuleStub1Path -ListAvailable
            $r.ExportedCommands.'Invoke-SomeCommand'.Parameters |
                Should beNullOrEmpty
        }
        It 'even if the module is imported first' {
            Import-Module $commandModuleStub1Path
            $r = Get-Module $commandModuleStub1Path -ListAvailable
            $r.ExportedCommands.'Invoke-SomeCommand'.Parameters |
                Should beNullOrEmpty
        }
    }
    Context 'Import-Module -PassThru' {
        It 'includes ExportedCommands' {
            $r = Import-Module $commandModuleStub1Path -PassThru
            $r.ExportedCommands | Should not beNullOrEmpty
        }
        It 'and the commands include parameters' {
            $r = Import-Module $commandModuleStub1Path -PassThru
            $r.ExportedCommands.'Invoke-SomeCommand'.Parameters |
                Should not beNullOrEmpty
        }
    }
}
