if ( $PSVersionTable.PSVersion -lt '5.0.0' ) { return }

Import-Module ToolFoundations -Force

InModuleScope ToolFoundations {

function Test-Item    { param ($Key) }
function Add-Item    { param ($Key,$CP) }
function Remove-Item { param ($Key) }

Describe 'Invoke-ProcessPersistentItem -Ensure Present: ' {
    Mock Test-Item -Verifiable
    Mock Add-Item -Verifiable
    Mock Remove-Item { 'junk' } -Verifiable
    Mock Invoke-ProcessPersistentItemProperty -Verifiable

    $delegates = @{
        Tester = 'Test-Item'
        Curer = 'Add-Item'
        Remover = 'Remove-Item'
        PropertyCurer = 'Set-Property'
        PropertyTester = 'Test-Property'
    }
    $coreDelegates = @{
        Tester = 'Test-Item'
        Curer = 'Add-Item'
        Remover = 'Remove-Item'
    }

    Context '-Ensure Present: absent, Set' {
        Mock Add-Item { 'item' }
        It 'returns nothing' {
            $splat = @{
                Keys = @{ Key = 'key value' }
                Properties = @{ P = 'P desired' }
                CurerParams = @{ CP = 'CP Param' }
            }
            $r = Invoke-ProcessPersistentItem Set Present @splat @delegates
            $r | Should beNullOrEmpty
        }
        It 'correctly invokes functions' {
            Assert-MockCalled Test-Item 1 { $Key -eq 'key value' }
            Assert-MockCalled Add-Item 1 {
                $Key -eq 'key value' -and
                $CP -eq 'CP Param'
            }
            Assert-MockCalled Remove-Item 0 -Exactly
            Assert-MockCalled Invoke-ProcessPersistentItemProperty 1 {
                $Mode -eq 'Set' -and
                $_Keys.Key -eq 'key value' -and
                $Properties.P -eq 'P desired' -and
                $PropertyCurer -eq 'Set-Property' -and
                $PropertyTester -eq 'Test-Property'
            }
        }
    }
    Context '-Ensure Present: absent, Set - omitting properties skips setting properties' {
        Mock Add-Item { 'item' }
        It 'returns nothing' {
            $splat = @{ Keys = @{ Key = 'key value' } }
            $r = Invoke-ProcessPersistentItem Set Present @splat @coreDelegates
            $r | Should beNullOrEmpty
        }
        It 'correctly invokes functions' {
            Assert-MockCalled Test-Item 1 { $Key -eq 'key value' }
            Assert-MockCalled Add-Item 1 { $Key -eq 'key value' }
            Assert-MockCalled Remove-Item 0 -Exactly
            Assert-MockCalled Invoke-ProcessPersistentItemProperty 0 -Exactly
        }
    }
    Context '-Ensure Present: absent, Test' {
        It 'returns false' {
            $splat = @{
                Keys = @{ Key = 'key value' }
                Properties = @{}
            }
            $r = Invoke-ProcessPersistentItem Test Present @splat @delegates
            $r | Should be $false
        }
        It 'correctly invokes functions' {
            Assert-MockCalled Test-Item 1 { $Key -eq 'key value' }
            Assert-MockCalled Add-Item 0 -Exactly
            Assert-MockCalled Remove-Item 0 -Exactly
            Assert-MockCalled Invoke-ProcessPersistentItemProperty 0 -Exactly
        }
    }
    Context '-Ensure Present: present, Set' {
        Mock Test-Item { $true } -Verifiable
        It 'returns nothing' {
            $splat = @{
                Keys = @{ Key = 'key value' }
                Properties = @{}
            }
            $r = Invoke-ProcessPersistentItem Set Present @splat @delegates
            $r | Should beNullOrEmpty
        }
        It 'correctly invokes functions' {
            Assert-MockCalled Test-Item 1 { $Key -eq 'key value' }
            Assert-MockCalled Add-Item 0 -Exactly
            Assert-MockCalled Remove-Item 0 -Exactly
            Assert-MockCalled Invoke-ProcessPersistentItemProperty 1
        }
    }
    Context '-Ensure Present: present, Test' {
        Mock Test-Item { $true } -Verifiable
        Mock Invoke-ProcessPersistentItemProperty { 'property test result' } -Verifiable
        It 'returns result of properties test' {
            $splat = @{
                Keys = @{ Key = 'key value' }
                Properties = @{}
            }
            $r = Invoke-ProcessPersistentItem Test Present @splat @delegates
            $r | Should be 'property test result'
        }
        It 'correctly invokes functions' {
            Assert-MockCalled Test-Item 1 { $Key -eq 'key value' }
            Assert-MockCalled Add-Item 0 -Exactly
            Assert-MockCalled Remove-Item 0 -Exactly
            Assert-MockCalled Invoke-ProcessPersistentItemProperty 1
        }
    }
    Context '-Ensure Present: present, Test - omitting properties skips setting properties' {
        Mock Test-Item { $true } -Verifiable
        It 'returns result of properties test' {
            $splat = @{ Keys = @{ Key = 'key value' } }
            $r = Invoke-ProcessPersistentItem Test Present @splat @coreDelegates
            $r | Should be $true
        }
        It 'correctly invokes functions' {
            Assert-MockCalled Test-Item 1 { $Key -eq 'key value' }
            Assert-MockCalled Add-Item 0 -Exactly
            Assert-MockCalled Remove-Item 0 -Exactly
            Assert-MockCalled Invoke-ProcessPersistentItemProperty 0 -Exactly
        }
    }
    Context '-Ensure Absent: absent, Set' {
        It 'returns nothing' {
            $splat = @{
                Keys = @{ Key = 'key value' }
                Properties = @{}
            }
            $r = Invoke-ProcessPersistentItem Set Absent @splat @delegates
            $r | Should beNullOrEmpty
        }
        It 'correctly invokes functions' {
            Assert-MockCalled Test-Item 1 { $Key -eq 'key value' }
            Assert-MockCalled Add-Item 0 -Exactly
            Assert-MockCalled Remove-Item 0 -Exactly
            Assert-MockCalled Invoke-ProcessPersistentItemProperty 0 -Exactly
        }
    }
    Context '-Ensure Absent: absent, Test' {
        It 'returns true' {
            $splat = @{
                Keys = @{ Key = 'key value' }
                Properties = @{}
            }
            $r = Invoke-ProcessPersistentItem Test Absent @splat @delegates
            $r | Should be $true
        }
        It 'correctly invokes functions' {
            Assert-MockCalled Test-Item 1 { $Key -eq 'key value' }
            Assert-MockCalled Add-Item 0 -Exactly
            Assert-MockCalled Remove-Item 0 -Exactly
            Assert-MockCalled Invoke-ProcessPersistentItemProperty 0 -Exactly
        }
    }
    Context '-Ensure Absent: present, Set' {
        Mock Test-Item { $true } -Verifiable
        It 'returns nothing' {
            $splat = @{
                Keys = @{ Key = 'key value' }
                Properties = @{}
            }
            $r = Invoke-ProcessPersistentItem Set Absent @splat @delegates
            $r | Should beNullOrEmpty
        }
        It 'correctly invokes functions' {
            Assert-MockCalled Test-Item 1 { $Key -eq 'key value' }
            Assert-MockCalled Add-Item 0 -Exactly
            Assert-MockCalled Remove-Item 1 { $Key -eq 'key value' }
            Assert-MockCalled Invoke-ProcessPersistentItemProperty 0 -Exactly
        }
    }
    Context '-Ensure Absent: present, Test' {
        Mock Test-Item { $true } -Verifiable
        It 'returns false' {
            $splat = @{
                Keys = @{ Key = 'key value' }
                Properties = @{}
            }
            $r = Invoke-ProcessPersistentItem Test Absent @splat @delegates
            $r | Should be $false
        }
        It 'correctly invokes functions' {
            Assert-MockCalled Test-Item 1 { $Key -eq 'key value' }
            Assert-MockCalled Add-Item 0 -Exactly
            Assert-MockCalled Remove-Item 0 -Exactly
            Assert-MockCalled Invoke-ProcessPersistentItemProperty 0 -Exactly
        }
    }
    Context '-Ensure Absent: Set, no remover' {
        It 'throws' {
            $splat = @{
                Keys = @{ Key = 'key value' }
                Tester = 'Test-Item'
                Curer = 'Add-Item'
            }
            { Invoke-ProcessPersistentItem Set Absent @splat } |
                Should throw 'no remover'
        }
    }
    Context '-Ensure Absent: absent, Test, no remover' {
        It 'returns true' {
            $splat = @{
                Keys = @{ Key = 'key value' }
                Tester = 'Test-Item'
                Curer = 'Add-Item'
            }
            $r = Invoke-ProcessPersistentItem Test Absent @splat
            $r | Should be $true
        }
    }
}


function Set-Property { param ($Key,$PropertyName,$Value) }
function Test-Property { param ($Key,$PropertyName,$Value) }

Describe 'Invoke-ProcessPersistentItemProperty' {
    Mock Set-Property { 'junk' } -Verifiable
    Mock Test-Property { $true } -Verifiable

    $delegates = @{
        PropertyCurer = 'Set-Property'
        PropertyTester = 'Test-Property'
    }
    Context 'Set, property already correct' {
        Mock Test-Property { $true } -Verifiable
        It 'returns nothing' {
            $splat = @{
                Keys = @{ Key = 'key value' }
                Properties = @{ P = 'correct' }
            }
            $r = Invoke-ProcessPersistentItemProperty Set @splat @delegates
            $r | Should beNullOrEmpty
        }
        It 'correctly invokes functions' {
            Assert-MockCalled Test-Property 1 {
                $Key -eq 'key value' -and
                $PropertyName -eq 'P' -and
                $Value -eq 'correct'
            }
            Assert-MockCalled Set-Property 0 -Exactly
        }
    }
    Context 'Test, property correct' {
        Mock Test-Property { $true } -Verifiable
        It 'returns true' {
            $splat = @{
                Keys = @{ Key = 'key value' }
                Properties = @{ P = 'correct' }
            }
            $r = Invoke-ProcessPersistentItemProperty Test @splat @delegates
            $r | Should be $true
        }
        It 'correctly invokes functions' {
            Assert-MockCalled Test-Property 1 {
                $Key -eq 'key value' -and
                $PropertyName -eq 'P' -and
                $Value -eq 'correct'
            }
            Assert-MockCalled Set-Property 0 -Exactly
        }
    }
    Context 'Set, correcting property' {
        Mock Test-Property { $false } -Verifiable
        It 'returns nothing' {
            $splat = @{
                Keys = @{ Key = 'key value' }
                Properties = @{ P = 'desired' }
            }
            $r = Invoke-ProcessPersistentItemProperty Set @splat @delegates
            $r | Should beNullOrEmpty
        }
        It 'correctly invokes functions' {
            Assert-MockCalled Set-Property 1 -Exactly {
                $Key -eq 'key value' -and
                $PropertyName -eq 'P' -and
                $Value -eq 'desired'
            }
            Assert-MockCalled Set-Property 1 -Exactly {
                $Key -eq 'key value' -and
                $PropertyName -eq 'P' -and
                $Value -eq 'desired'
            }
        }
    }
    Context 'Test, property incorrect' {
        Mock Test-Property { $false } -Verifiable
        It 'returns false' {
            $splat = @{
                Keys = @{ Key = 'key value' }
                Properties = @{ P = 'desired' }
            }
            $r = Invoke-ProcessPersistentItemProperty Test @splat @delegates
            $r | Should be $false
        }
        It 'correctly invokes functions' {
            Assert-MockCalled Test-Property 1 {
                $Key -eq 'key value' -and
                $PropertyName -eq 'P' -and
                $Value -eq 'desired'
            }
            Assert-MockCalled Set-Property 0 -Exactly
        }
    }
}
}
