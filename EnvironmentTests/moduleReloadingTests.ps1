$guid = '2282bfa0-cfdc-4ee5-a7a4-7aca5b33dc9f'
$workingFolderPath = "$([System.IO.Path]::GetTempPath())$guid"

$moduleContents = [ordered]@{
    NoClasses = @{
        Root = @'
Import-Module "$PSScriptRoot\Sub.psm1" -Args $Args
$passedArgs = $Args
function Get-PassedArgsRoot { $passedArgs }
'@
        Sub = @'
$passedArgs = $Args
function Get-PassedArgsSub { $passedArgs }
'@
    }
    Classes = @{
        Root = @'
Import-Module "$PSScriptRoot\Sub.psm1" -Args $Args
$passedArgs = $Args
class Root { $passedArgs = $passedArgs }
function Get-PassedArgsRoot { [Root]::new().passedArgs }
'@
        Sub = @'
$passedArgs = $Args
class Sub { $passedArgs = $passedArgs }
function Get-PassedArgsSub { [Sub]::new().passedArgs }
'@
    }
}

foreach ( $contentsName in $moduleContents.Keys )
{
    $values = @{
                   # args1,     root1,     sub1,      args2,     root2,     sub2
      # NoClasses = 'value 1', 'value 1', 'value 1', 'value 2', 'value 2', 'value 2' # <== how it should be
        NoClasses = 'value 1', 'value 1', 'value 1', 'value 2', 'value 2', 'value 1' # <== how it actually is

      # Classes   = 'value 1', 'value 1', 'value 1', 'value 2', 'value 2', 'value 2' # <== how it should be
        Classes   = 'value 1', 'value 1', 'value 1', 'value 2', 'value 1', 'value 1' # <== how it actually is
    }
    $args1,$root1,$sub1,$args2,$root2,$sub2 = $values.$contentsName
    $moduleName = "DifferentArgs_$contentsName"
    Describe "$moduleName" {
        $rootModuleFolderPath = "$workingFolderPath\$moduleName"
        Context 'set up the module files' {
            It 'create the root module folder' {
                New-Item $rootModuleFolderPath -ItemType Container -Force
            }
            It 'create the root module file' {
                $moduleContents.$contentsName.Root | Set-Content "$rootModuleFolderPath\$moduleName.psm1" -Force -ea Stop
            }
            It 'create the sub module file' {
                $moduleContents.$contentsName.Sub | Set-Content "$rootModuleFolderPath\Sub.psm1"
            }
        }
        Context "Import-Module with argument $args1 and test" {
            It 'import the root module with value 1' {
                Import-Module $rootModuleFolderPath -Args $args1 -Force -PassThru -ea Stop
            }
            It "the root module returns $root1" {
                $r = Get-PassedArgsRoot
                $r | Should be $root1
            }
            It "the sub module returns $sub1" {
                $r = Get-PassedArgsSub
                $r | Should be $sub1
            }
        }
        Context "Import-Module with argument $args2 and test" {
            It 'import the root module with value 1' {
                Import-Module $rootModuleFolderPath -Args $args2 -Force -PassThru -ea Stop
            }
            It "the root module returns $root2" {
                $r = Get-PassedArgsRoot
                $r | Should be $root2
            }
            It "the sub module returns $sub2" {
                $r = Get-PassedArgsSub
                $r | Should be $sub2
            }
        }
    }
}

$moduleContents = [ordered]@{
    NoClasses = @{
        RootContent1 = @'
Import-Module "$PSScriptRoot\Sub.psm1"
function Get-ValueRoot { 'value 1' }
'@
        RootContent2 = @'
Import-Module "$PSScriptRoot\Sub.psm1"
function Get-ValueRoot { 'value 2' }
'@
        SubContent1 = @'
function Get-ValueSub { 'value 1' }
'@
        SubContent2 = @'
function Get-ValueSub { 'value 2' }
'@
    }
    Classes = @{
        RootContent1 = @'
Import-Module "$PSScriptRoot\Sub.psm1"
class Root { $p = 'value 1' }
function Get-ValueRoot { [Root]::new().p }
'@
        RootContent2 = @'
Import-Module "$PSScriptRoot\Sub.psm1"
class Root { $p = 'value 2' }
function Get-ValueRoot { [Root]::new().p }
'@
        SubContent1 = @'
class Sub { $p = 'value 1' }
function Get-ValueSub { [Sub]::new().p }
'@
        SubContent2 = @'
class Sub { $p = 'value 2' }
function Get-ValueSub { [Sub]::new().p }
'@
    }
}

foreach ( $contentsName in $moduleContents.Keys )
{
    $tests = @(
        # |                                       |           Expected Values                     |
        # | modulePrefix|  changeRoot | changeSub | rootBefore | rootAfter | subBefore | subAfter |

      # @( 'ChangeBoth', $true,       $true,     'value 1',   'value 2',  'value 1',  'value 2' ), # <== how it should be
        @( 'ChangeBoth', $true,       $true,     'value 1',   'value 2',  'value 1',  'value 1' ), # <== how it actually is

      # @( 'ChangeSub',  $false,      $true,     'value 1',   'value 1',  'value 1',  'value 2' ), # <== how it should be
        @( 'ChangeSub',  $false,      $true,     'value 1',   'value 1',  'value 1',  'value 1' ), # <== how it actually is

        @( 'ChangeRoot', $true,       $false,    'value 1',   'value 2',  'value 1',  'value 1' )
    )

    foreach ( $values in $tests )
    {
        $modulePrefix,$changeRoot,$changeSub,$rootBefore,$rootAfter,$subBefore,$subAfter = $values
        $moduleName = "$modulePrefix`_$contentsName"
        Describe "reloading modules after changes - $moduleName" {
            $rootModuleFolderPath = "$workingFolderPath\$moduleName"
            Context 'set up the module files' {
                It 'create the root module folder' {
                    New-Item $rootModuleFolderPath -ItemType Container -Force
                }
                It 'create the root module file' {
                    $moduleContents.$contentsName.RootContent1 | Set-Content "$rootModuleFolderPath\$moduleName.psm1" -Force -ea Stop
                }
                It 'create the sub module file' {
                    $moduleContents.$contentsName.SubContent1 | Set-Content "$rootModuleFolderPath\Sub.psm1"
                }
            }
            Context 'import the module and test' {
                It 'import the module' {
                    Import-Module $rootModuleFolderPath -Force -ea Stop
                }
                It "root returns $rootBefore" {
                    $r = Get-ValueRoot
                    $r | Should be $rootBefore
                }
                It "sub returns $subBefore" {
                    $r = Get-ValueSub
                    $r | Should be $subBefore
                }
            }
            Context 'change contents' {
                if ( $changeRoot )
                {
                    It 'overwrite the root module file' {
                        $moduleContents.$contentsName.RootContent2 |
                            Set-Content "$rootModuleFolderPath\$moduleName.psm1" -Force -ea Stop
                    }
                }
                if ( $changeSub )
                {
                    It 'overwrite the sub module file' {
                        $moduleContents.$contentsName.SubContent2 |
                            Set-Content "$rootModuleFolderPath\Sub.psm1" -Force -ea Stop
                    }
                }
            }
            Context 're-import the module and test' {
                It 're-import the module' {
                    Import-Module $rootModuleFolderPath -Force -ea Stop
                }
                It "root returns $rootAfter" {
                    $r = Get-ValueRoot
                    $r | Should be $rootAfter
                }
                It "sub returns $subAfter" {
                    $r = Get-ValueSub
                    $r | Should be $subAfter
                }
            }
        }
    }
}
