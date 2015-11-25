Import-Module ToolFoundations -Force

InModuleScope ToolFoundations {
if ($PSVersionTable.PSVersion.Major -ge 4)
{
Describe Compare-SignedScriptContent {
    It 'matches contents after signing (1).' {
        $pathObj = "$($PSCommandPath | Split-Path -Parent)\..\Resources\signature-test-1.ps1" | 
            Resolve-FilePath |
            ConvertTo-FilePathObject
        $pathHash = @{
            DriveLetter = $pathObj.DriveLetter
            Segments = $pathObj.Segments
        }
        $splat = @{
            ScriptPath = $pathHash
            RefContents = @'
trailing newline

'@
        }
        $r = Compare-SignedScriptContent @splat
        $r | Should be $true
    }
    It 'matches contents after signing (2).' {
        $pathObj = "$($PSCommandPath | Split-Path -Parent)\..\Resources\signature-test-2.ps1" | 
            Resolve-FilePath |
            ConvertTo-FilePathObject
        $pathHash = @{
            DriveLetter = $pathObj.DriveLetter
            Segments = $pathObj.Segments
        }
        $splat = @{
            ScriptPath = $pathHash
            RefContents = 'no trailing newline'
        }
        $r = Compare-SignedScriptContent @splat
        $r | Should be $true
    }
    It 'fails.' {
        $pathObj = "$($PSCommandPath | Split-Path -Parent)\..\Resources\signature-test-2.ps1" | 
            Resolve-FilePath |
            ConvertTo-FilePathObject
        $pathHash = @{
            DriveLetter = $pathObj.DriveLetter
            Segments = $pathObj.Segments
        }
        $splat = @{
            ScriptPath = $pathHash
            RefContents = 'this does not match'
        }
        $r = Compare-SignedScriptContent @splat
        $r | Should be $false
    }
    Context 'empty file' {
        Mock Get-Content {}
        It 'handles empty script file.' {
            $splat = @{
                ScriptPath = @{
                    DriveLetter = 'a'
                    Segments = 'path.ps1'
                }
                RefContents = 'content'
            }
            $r = Compare-SignedScriptContent @splat
            $r | Should be $false
        }
    }
    Context 'empty file' {
        Mock Get-Content {}
        It 'handles empty script file and empty string.' {
            $splat = @{
                ScriptPath = @{
                    DriveLetter = 'a'
                    Segments = 'path.ps1'
                }
                RefContents = [string]::Empty
            }
            $r = Compare-SignedScriptContent @splat
            $r | Should be $true
        }
    }
}
}
}