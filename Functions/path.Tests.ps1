Import-Module ToolFoundations -Force

Describe Test-ValidDriveLetter {
    It 'returns true for good drive letter.' {
        'a' | Test-ValidDriveLetter | Should be $true
        'A' | Test-ValidDriveLetter | Should be $true
        'z' | Test-ValidDriveLetter | Should be $true
    }
    It 'returns false for bad drive letter.' {
        'aa' | Test-ValidDriveLetter | Should be $false
        '_' | Test-ValidDriveLetter | Should be $false
        '1' | Test-ValidDriveLetter | Should be $false
    }
}
Describe Test-ValidFilename{
    It 'returns true for valid filename.' {
        'a' | Test-ValidFileName | Should be $true
        'a.b' | Test-ValidFileName | Should be $true
    }
    It 'returns false for an invalid characters.' {
        'b<d' | Test-ValidFileName | Should be $false
        'b*d' | Test-ValidFileName | Should be $false
        'inva|id' | Test-ValidFileName | Should be $false
        'c:' | Test-ValidFileName | Should be $false
    }
    It 'returns false for all periods.' {
        '.' | Test-ValidFileName | Should be $false
        '..' | Test-ValidFileName | Should be $false
    }
    It 'returns false for DOS Names.' {
        'PRN.' | Test-ValidFileName | Should be $false
        'PRN' | Test-ValidFileName | Should be $false
        'AUX.txt' | Test-ValidFileName | Should be $false
        'AUXtxt' | Test-ValidFileName | Should be $true
    }
    It 'returns false for filename that is too long.' {
        $s = '0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789'+
        '0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789'+
        '0123456789012345678901234567890123456789012345678901234'

        $s.Length | Should be 255
        $s | Test-ValidFileName | Should be $true
        $s = $s+'5'
        $s.Length | Should be 256
        $s | Test-ValidFileName | Should be $false
    }
}
InModuleScope ToolFoundations {
    Describe Test-ValidFilePathFragment {
        It 'returns true.' {
            'good\frag' | Test-ValidFilePathFragment | Should be $true
            'good/frag' | Test-ValidFilePathFragment | Should be $true
        }
        it 'return false.' {
            'bad\path/fragment' | Test-ValidFilePathFragment | Should be $false
            'bad/pa:h/fragment' | Test-ValidFilePathFragment | Should be $false
        }
        Context 'validates good element' {
            Mock Test-ValidFileName -Verifiable {$true}
            It 'returns true.' {
                $r = 'good\frag' | Test-ValidFilePathFragment
                $r | Should be $true

                Assert-MockCalled Test-ValidFileName -Times 1 {
                    $FileName -eq 'good'
                }
                Assert-MockCalled Test-ValidFileName -Times 1 {
                    $FileName -eq 'frag'
                }
            }
        }
        Context 'validates bad element' {
            Mock Test-ValidFileName -Verifiable {$false}
            It 'returns true.' {
                $r = 'bad\frag' | Test-ValidFilePathFragment
                $r | Should be $false

                Assert-MockCalled Test-ValidFileName -Times 1 {
                    $FileName -eq 'bad'
                }
            }
        }
    }
}
Describe Split-FilePathFragment {
    It 'produces correct result.' {
        $r = 'path/fragment' | Split-FilePathFragment
        $r[0] | Should be 'path'
        $r[1] | Should be 'fragment'
        $r.Count | Should be '2'

        $r = 'path\fragment' | Split-FilePathFragment
        $r[0] | Should be 'path'
        $r[1] | Should be 'fragment'
        $r.Count | Should be '2'

        $r = 'c:\path\fragment' | Split-FilePathFragment
        $r[0] | Should be 'c:'
        $r[1] | Should be 'path'
        $r[2] | Should be 'fragment'
        $r.Count | Should be '3'
    }
}
Describe ConvertTo-FilePathWithoutPrefix {
    It 'PowerShell Windows path' {
        $r = 'c:\path' | ConvertTo-FilePathWithoutPrefix
        $r | Should be 'c:\path'
    }
    It 'UNC path' {
        $r = '\\server\path' | ConvertTo-FilePathWithoutPrefix
        $r | Should be '\\server\path'
    }
    It 'PowerShell Windows Path' {
        $r = 'FileSystem::c:\path' | ConvertTo-FilePathWithoutPrefix
        $r | Should be 'c:\path'
    }
    It 'long prefix PowerShell Windows Path' {
        $r = 'Microsoft.PowerShell.Core\FileSystem::c:\path' | ConvertTo-FilePathWithoutPrefix
        $r | Should be 'c:\path'
    }
    It 'PowerShell UNC Path' {
        $r = 'FileSystem::\\server\path' | ConvertTo-FilePathWithoutPrefix
        $r | Should be '\\server\path'
    }
    It 'long prefix PowerShell UNC Path' {
        $r = 'Microsoft.PowerShell.Core\FileSystem::\\server\path' | ConvertTo-FilePathWithoutPrefix
        $r | Should be '\\server\path'
    }
    It 'URI Windows Path' {
        $r = 'file:///c:/path' | ConvertTo-FilePathWithoutPrefix
        $r | Should be 'c:/path'
    }
    It 'URI UNC Path' {
        $r = 'file://server/path' | ConvertTo-FilePathWithoutPrefix
        $r | Should be '//server/path'
    }
}
InModuleScope ToolFoundations {
    Describe Test-ValidUncFilePath {
        Context 'mixed slashes' {
            Mock Write-Verbose -Verifiable
            It 'returns false.' {
                $r = '\\server/path' | Test-ValidUncFilePath
                $r | Should be $false

                Assert-MockCalled Write-Verbose -Times 1 {
                    $Message -eq 'Path \\server/path has mixed slashes.'
                }
            }
        }
        Context 'strips prefix' {
            Mock ConvertTo-FilePathWithoutPrefix -Verifiable {'c:'}
            Mock Write-Error
            It 'invokes strip function' {
                $r = 'path' | Test-ValidUncFilePath

                Assert-MockCalled ConvertTo-FilePathWithoutPrefix -Times 1 {
                    $Path -eq 'path'
                }
            }
        }
        Context 'not UNC Path' {
            Mock ConvertTo-FilePathWithoutPrefix {'not a real path'}
            It 'returns false.' {
                $r = 'path' | Test-ValidUncFilePath
                $r | Should be $false
            }
        }
        Context 'validates domain name' {
            Mock ConvertTo-FilePathWithoutPrefix {'\\server\path'}
            Mock Test-ValidDomainName -Verifiable
            Mock Write-Error
            It 'tests domain name' {
                'path' | Test-ValidUncFilePath

                Assert-MockCalled Test-ValidDomainName -Times 1 {
                    $DomainName -eq 'server'
                }
            }
        }
        Context 'invalid domain name' {
            Mock ConvertTo-FilePathWithoutPrefix {'\\server\path'}
            Mock Test-ValidDomainName {$false}
            Mock Write-Verbose -Verifiable
            It 'returns false.' {
                $r = 'path' | Test-ValidUncFilePath
                $r | Should be $false

                Assert-MockCalled Write-Verbose -Times 1 {
                    $Message -eq 'Seems like a UNC path, but server is not a valid domain name.'
                }
            }
        }
        Context 'tests driveletter' {
            Mock ConvertTo-FilePathWithoutPrefix {'\\server\c$\path'}
            Mock Test-ValidDomainName {$true}
            Mock Test-ValidDriveLetter -Verifiable
            It 'invokes test function.' {
                'path' | Test-ValidUncFilePath

                Assert-MockCalled Test-ValidDriveLetter -Times 1 {
                    $DriveLetter -eq 'c'
                }
            }
        }
        Context 'bad driveletter' {
            Mock ConvertTo-FilePathWithoutPrefix {'\\server\c$\path'}
            Mock Test-ValidDomainName {$true}
            Mock Test-ValidDriveLetter {$false}
            Mock Write-Verbose -Verifiable
            It 'returns false.' {
                $r = 'path' | Test-ValidUncFilePath
                $r | Should be $false

                Assert-MockCalled Write-Verbose -Times 1 {
                    $Message -eq 'Seems like a UNC path administrative share, but c is not a valid drive letter.'
                }
            }
        }
        Context 'test path fragment' {
            Mock ConvertTo-FilePathWithoutPrefix {'\\server\path'}
            Mock Test-ValidDomainName {$true}
            Mock Test-ValidDriveLetter {$true}
            Mock Test-ValidFilePathFragment -Verifiable
            It 'invokes test function' {
                'path' | Test-ValidUncFilePath

                Assert-MockCalled Test-ValidFilePathFragment -Times 1 {
                    $Path -eq '\path'
                }
            }
        }
        Context 'bad path fragment' {
            Mock ConvertTo-FilePathWithoutPrefix {'\\server\path'}
            Mock Test-ValidDomainName {$true}
            Mock Test-ValidDriveLetter {$true}
            Mock Test-ValidFilePathFragment {$false}
            Mock Write-Verbose -Verifiable
            It 'returns false.' {
                $r = 'path' | Test-ValidUncFilePath
                $r | Should be $false

                Assert-MockCalled Write-Verbose -Times 1 {
                    $Message -eq 'Seems like a UNC path, but \path is not a valid path fragment.'
                }
            }
        }
        Context 'UNC path' {
            Mock ConvertTo-FilePathWithoutPrefix {'\\server\path'}
            Mock Test-ValidDomainName {$true}
            Mock Test-ValidDriveLetter {$true}
            Mock Test-ValidFilePathFragment {$true}
            It 'returns correct type' {
                $r = 'path' | Test-ValidUncFilePath
                $r | Should be $true
            }
        }
    }
}
InModuleScope ToolFoundations {
    Describe Test-ValidWindowsFilePath {
        Context 'mixed slashes' {
            Mock Write-Verbose -Verifiable
            It 'returns false.' {
                $r = 'c:\windows/path' | Test-ValidWindowsFilePath
                $r | Should be $false

                Assert-MockCalled Write-Verbose -Times 1 {
                    $Message -eq 'Path c:\windows/path has mixed slashes.'
                }
            }
        }
        Context 'strips prefix' {
            Mock ConvertTo-FilePathWithoutPrefix -Verifiable {'not windows path'}
            It 'invokes strip function' {
                $r = 'path' | Test-ValidWindowsFilePath

                Assert-MockCalled ConvertTo-FilePathWithoutPrefix -Times 1 {
                    $Path -eq 'path'
                }
            }
        }
        Context 'not Windows Path' {
            Mock ConvertTo-FilePathWithoutPrefix {'not a real path'}
            It 'returns false.' {
                $r = 'path' | Test-ValidWindowsFilePath
                $r | Should be $false
            }
        }
        Context 'tests driveletter' {
            Mock ConvertTo-FilePathWithoutPrefix {'c:\path'}
            Mock Test-ValidDriveLetter -Verifiable
            It 'invokes test function.' {
                'path' | Test-ValidWindowsFilePath

                Assert-MockCalled Test-ValidDriveLetter -Times 1 {
                    $DriveLetter -eq 'c'
                }
            }
        }
        Context 'bad driveletter' {
            Mock ConvertTo-FilePathWithoutPrefix {'c:\path'}
            Mock Test-ValidDriveLetter {$false}
            Mock Write-Verbose -Verifiable
            It 'returns false.' {
                $r = 'path' | Test-ValidWindowsFilePath
                $r | Should be $false

                Assert-MockCalled Write-Verbose -Times 1 {
                    $Message -eq 'Path path seems like a Windows path but c is not a valid drive letter.'
                }
            }
        }
        Context 'test path fragment' {
            Mock ConvertTo-FilePathWithoutPrefix {'c:\path'}
            Mock Test-ValidDriveLetter {$true}
            Mock Test-ValidFilePathFragment -Verifiable
            It 'invokes test function' {
                'path' | Test-ValidWindowsFilePath

                Assert-MockCalled Test-ValidFilePathFragment -Times 1 {
                    $Path -eq '\path'
                }
            }
        }
        Context 'bad path fragment' {
            Mock ConvertTo-FilePathWithoutPrefix {'c:\path'}
            Mock Test-ValidDriveLetter {$true}
            Mock Test-ValidFilePathFragment {$false}
            Mock Write-Verbose -Verifiable
            It 'returns false.' {
                $r = 'path' | Test-ValidWindowsFilePath
                $r | Should be $false

                Assert-MockCalled Write-Verbose -Times 1 {
                    $Message -eq 'Path path seems like a Windows path but \path is not a valid path fragment.'
                }
            }
        }
        Context 'Windows path' {
            Mock ConvertTo-FilePathWithoutPrefix {'c:\path'}
            Mock Test-ValidDriveLetter {$true}
            Mock Test-ValidFilePathFragment {$true}
            It 'returns true.' {
                $r = 'path' | Test-ValidWindowsFilePath
                $r | Should be $true
            }
        }

    }
}
InModuleScope ToolFoundations {
    Describe Get-PartOfUncPath {
        Context 'strips prefix' {
            Mock ConvertTo-FilePathWithoutPrefix -Verifiable {'not UNC path'}
            It 'invokes strip function' {
                $r = 'path' | Get-PartOfUncPath DomainName

                Assert-MockCalled ConvertTo-FilePathWithoutPrefix -Times 1 {
                    $Path -eq 'path'
                }
            }
        }
        It 'produces correct results.' {
            'file://domain.name/c$/path/fragment' | Get-PartOfUncPath DomainName | Should be 'domain.name'
            'file://domain.name/c$/path/fragment' | Get-PartOfUncPath DriveLetter | Should be 'c'
            'file://domain.name/c$/path/fragment' | Get-PartOfUncPath Path | Should be '/path/fragment'
            'file://domain.name/path/fragment' | Get-PartOfUncPath DomainName | Should be 'domain.name'
            'file://domain.name/path/fragment' | Get-PartOfUncPath DriveLetter | Should be $false
            'file://domain.name/path/fragment' | Get-PartOfUncPath Path | Should be '/path/fragment'
            'FileSystem::\\domain.name\c$\path\fragment' | Get-PartOfUncPath DomainName | Should be 'domain.name'
            'FileSystem::\\domain.name\c$\path\fragment' | Get-PartOfUncPath DriveLetter | Should be 'c'
            'FileSystem::\\domain.name\c$\path\fragment' | Get-PartOfUncPath Path | Should be '\path\fragment'
            'FileSystem::\\domain.name\path\fragment' | Get-PartOfUncPath DomainName | Should be 'domain.name'
            'FileSystem::\\domain.name\path\fragment' | Get-PartOfUncPath DriveLetter | Should be $false
            'FileSystem::\\domain.name\path\fragment' | Get-PartOfUncPath Path | Should be '\path\fragment'
        }
    }
    Describe 'Get-PartOfUncPath DomainName' {
        Context 'correct results' {
            Mock ConvertTo-FilePathWithoutPrefix {$Path}
            It 'produces correct results' {
                '\\domain.name\path' | Get-PartOfUncPath DomainName | Should be 'domain.name'
                '\domain.name\path' | Get-PartOfUncPath DomainName | Should be $false
                'domain.name\path' | Get-PartOfUncPath DomainName | Should be $false
                '//domain.name/path' | Get-PartOfUncPath DomainName | Should be 'domain.name'
                '/domain.name/path' | Get-PartOfUncPath DomainName | Should be $false
                'domain.name\path' | Get-PartOfUncPath DomainName | Should be $false
                '\\domainname/path' | Get-PartOfUncPath DomainName | Should be 'domainname'
                '//domainname\path' | Get-PartOfUncPath DomainName | Should be 'domainname'
                '\\domain.name' | Get-PartOfUncPath DomainName | Should be 'domain.name'
                '//domain.name' | Get-PartOfUncPath DomainName | Should be 'domain.name'
                '/\domain.name' | Get-PartOfUncPath DomainName | Should be $false
                '\/domain.name' | Get-PartOfUncPath DomainName | Should be $false
            }
        }
    }
    Describe 'Get-PartOfUncPath DriveLetter'{
        Context 'correct results' {
            Mock ConvertTo-FilePathWithoutPrefix {$Path}
            It 'produces correct results' {
                '\\domain' | Get-PartOfUncPath DriveLetter | Should be $false
                '\\domain\c$' | Get-PartOfUncPath DriveLetter | Should be 'c'
                '\\domain\c$\' | Get-PartOfUncPath DriveLetter | Should be 'c'
                '\\domain\cc$\'  | Get-PartOfUncPath DriveLetter | Should be 'cc'
                '//domain/c$' | Get-PartOfUncPath DriveLetter | Should be 'c'
                '//domain/c$/' | Get-PartOfUncPath DriveLetter | Should be 'c'
                '//domain/cc$/'  | Get-PartOfUncPath DriveLetter | Should be 'cc'
                '\\domain\c'  | Get-PartOfUncPath DriveLetter | Should be $false
                '\\domain\c\'  | Get-PartOfUncPath DriveLetter | Should be $false
                '\\domain\c\c$'  | Get-PartOfUncPath DriveLetter | Should be $false
                '\\domain/c$'  | Get-PartOfUncPath DriveLetter | Should be 'c'
                '\\domain/c$/'  | Get-PartOfUncPath DriveLetter | Should be 'c'
            }
        }
    }
    Describe 'Get-PartOfUncPath Path'{
        Context 'correct results' {
            Mock ConvertTo-FilePathWithoutPrefix {$Path}
            It 'produces correct results' {
                '\\domain' | Get-PartOfUncPath Path | Should be $false
                '\\domain\c$' | Get-PartOfUncPath Path | Should be $false
                '\\domain\c$\' | Get-PartOfUncPath Path | Should be '\'
                '\\domain\c$/' | Get-PartOfUncPath Path | Should be '/'
                '\\domain/c$/' | Get-PartOfUncPath Path | Should be '/'
                '\\domain\c$\path' | Get-PartOfUncPath Path | Should be '\path'
                '\\domain\c$\path\frag' | Get-PartOfUncPath Path | Should be '\path\frag'
                '\\domain\c$\c$' | Get-PartOfUncPath Path | Should be '\c$'
                '\\domain' | Get-PartOfUncPath Path | Should be $false
                '\\domain\' | Get-PartOfUncPath Path | Should be '\'
                '\\domain/' | Get-PartOfUncPath Path | Should be '/'
                '\\domain\path' | Get-PartOfUncPath Path | Should be '\path'
                '\\domain\path\frag' | Get-PartOfUncPath Path | Should be '\path\frag'
                '//domain/c$' | Get-PartOfUncPath Path | Should be $false
                '//domain/c$/' | Get-PartOfUncPath Path | Should be '/'
                '//domain/c$\' | Get-PartOfUncPath Path | Should be '\'
                '//domain\c$\' | Get-PartOfUncPath Path | Should be '\'
                '//domain/c$/path' | Get-PartOfUncPath Path | Should be '/path'
                '//domain/c$/path/frag' | Get-PartOfUncPath Path | Should be '/path/frag'
                '//domain/c$/c$' | Get-PartOfUncPath Path | Should be '/c$'
                '//domain' | Get-PartOfUncPath Path | Should be $false
                '//domain/' | Get-PartOfUncPath Path | Should be '/'
                '//domain\' | Get-PartOfUncPath Path | Should be '\'
                '//domain/path' | Get-PartOfUncPath Path | Should be '/path'
                '//domain/path/frag' | Get-PartOfUncPath Path | Should be '/path/frag'
            }
        }
    }
}
InModuleScope ToolFoundations {
    Describe Get-PartOfWindowsPath {
        Context 'strips prefix' {
            Mock ConvertTo-FilePathWithoutPrefix -Verifiable {'not Windows path'}
            It 'invokes strip function' {
                $r = 'path' | Get-PartOfWindowsPath DriveLetter

                Assert-MockCalled ConvertTo-FilePathWithoutPrefix -Times 1 {
                    $Path -eq 'path'
                }
            }
        }
        It 'produces correct results.' {
            'file:///c:/path' | Get-PartOfWindowsPath DriveLetter | Should be 'c'
            'file:///c:path.txt' | Get-PartOfWindowsPath DriveLetter | Should be 'c'
            'file:///c:/path' | Get-PartOfWindowsPath Path | Should be '/path'
            'file:///c:path.txt' | Get-PartOfWindowsPath Path | Should be 'path.txt'
            'c:\path' | Get-PartOfWindowsPath DriveLetter | Should be 'c'
            'c:/path' | Get-PartOfWindowsPath DriveLetter | Should be 'c'
            'c:path.txt' | Get-PartOfWindowsPath DriveLetter | Should be 'c'
            'c:\path' | Get-PartOfWindowsPath Path | Should be '\path'
            'c:/path' | Get-PartOfWindowsPath Path | Should be '/path'
            'c:path.txt' | Get-PartOfWindowsPath Path | Should be 'path.txt'
        }
    }
    Describe 'Get-PartOfWindowsPath DriveLetter'{
        Context 'correct results' {
            Mock ConvertTo-FilePathWithoutPrefix {$Path}
            It 'produces correct results' {
                '\c' | Get-PartOfWindowsPath DriveLetter | Should be $false
                '\c:' | Get-PartOfWindowsPath DriveLetter | Should be $false
                'c' | Get-PartOfWindowsPath DriveLetter | Should be $false
                'c:' | Get-PartOfWindowsPath DriveLetter | Should be 'c'
                'c:path' | Get-PartOfWindowsPath DriveLetter | Should be 'c'
                'c$path' | Get-PartOfWindowsPath DriveLetter | Should be $false
                'c$\path' | Get-PartOfWindowsPath DriveLetter | Should be $false
                'c:\' | Get-PartOfWindowsPath DriveLetter | Should be 'c'
                'c:/' | Get-PartOfWindowsPath DriveLetter | Should be 'c'
                'c:/path' | Get-PartOfWindowsPath DriveLetter | Should be 'c'
                'c:\path' | Get-PartOfWindowsPath DriveLetter | Should be 'c'
                'cc:\path' | Get-PartOfWindowsPath DriveLetter | Should be 'cc'
                'cc:/path' | Get-PartOfWindowsPath DriveLetter | Should be 'cc'
            }
        }
    }
    Describe 'Get-PartOfWindowsPath Path' {
        Context 'correct results' {
            Mock ConvertTo-FilePathWithoutPrefix {$Path}
            It 'produces correct results' {
                'c$path' | Get-PartOfWindowsPath Path | Should be $false
                'c.path' | Get-PartOfWindowsPath Path | Should be $false
                'c:' | Get-PartOfWindowsPath Path | Should be $false
                'c:\' | Get-PartOfWindowsPath Path | Should be '\'
                'c:/' | Get-PartOfWindowsPath Path | Should be '/'
                'c:path' | Get-PartOfWindowsPath Path | Should be 'path'
                'c:\path' | Get-PartOfWindowsPath Path | Should be '\path'
                'c:/path' | Get-PartOfWindowsPath Path | Should be '/path'
                'c:path.txt' | Get-PartOfWindowsPath Path | Should be 'path.txt'
                'c:\path\fragment' | Get-PartOfWindowsPath Path | Should be '\path\fragment'
            }
        }
    }
}
InModuleScope ToolFoundations {
    Describe Get-FilePathType {
        Context 'tests for Windows Path' {
            Mock Test-ValidWindowsFilePath -Verifiable
            It 'invokes test function' {
                'path' | Get-FilePathType

                Assert-MockCalled Test-ValidWindowsFilePath -Times 1 {
                    $Path -eq 'path'
                }
            }
        }
        Context 'tests for UNC Path' {
            Mock Test-ValidUncFilePath -Verifiable
            It 'invokes test function' {
                'path' | Get-FilePathType

                Assert-MockCalled Test-ValidUncFilePath -Times 1 {
                    $Path -eq 'path'
                }
            }
        }
        Context 'ambiguous' {
            Mock Test-ValidUncFilePath {$true}
            Mock Test-ValidWindowsFilePath {$true}
            Mock Write-Verbose -Verifiable
            It 'returns correct value.' {
                $r = 'path' | Get-FilePathType
                $r | Should be 'ambiguous'

                Assert-MockCalled Write-Verbose -Times 1 {
                    $Message -eq 'path could be Windows or UNC.'
                }
            }
        }
        Context 'windows' {
            Mock Test-ValidUncFilePath {$false}
            Mock Test-ValidWindowsFilePath {$true}
            It 'returns correct value.' {
                $r = 'path' | Get-FilePathType
                $r | Should be 'Windows'
            }
        }
        Context 'UNC' {
            Mock Test-ValidUncFilePath {$true}
            Mock Test-ValidWindowsFilePath {$false}
            It 'returns correct value.' {
                $r = 'path' | Get-FilePathType
                $r | Should be 'UNC'
            }
        }
        Context 'unknown' {
            Mock Test-ValidUncFilePath {$false}
            Mock Test-ValidWindowsFilePath {$false}
            It 'returns correct value.' {
                $r = 'path' | Get-FilePathType
                $r | Should be 'unknown'
            }
        }
    }
}
InModuleScope ToolFoundations {
    Describe ConvertTo-FilePathHashtable {
        Context 'tests file path type' {
            Mock Get-FilePathType -Verifiable
            Mock Write-Error
            It 'invokes test function.' {
                'path' | ConvertTo-FilePathHashtable

                Assert-MockCalled Get-FilePathType -Times 1 {
                    $Path -eq 'path'
                }
            }
        }
        Context 'ambiguous type' {
            Mock Get-FilePathType {'ambiguous'}
            Mock Write-Error -Verifiable
            It 'reports correct error' {
                $r = 'path' | ConvertTO-FilePathHashTable
                $r | Should be $false

                Assert-MockCalled Write-Error -Times 1 {
                    $Message -eq 'Path type of path is ambiguous.'
                }
            }
        }
        Context 'unknown type' {
            Mock Get-FilePathType {'unknown'}
            Mock Write-Error -Verifiable
            It 'reports correct error' {
                $r = 'path' | ConvertTO-FilePathHashTable
                $r | Should be $false

                Assert-MockCalled Write-Error -Times 1 {
                    $Message -eq 'Path type of path is unknown.'
                }
            }
        }
        Context 'calls Get-Part for Windows Path' {
            Mock Get-FilePathType {'Windows'}
            Mock Get-PartOfWindowsPath -Verifiable
            It 'invokes Get-Part function' {
                'path' | ConvertTo-FilePathHashTable

                Assert-MockCalled Get-PartOfWindowsPath -Times 1 {
                    $PartName -eq 'Path' -and
                    $Path -eq 'path'
                }
                Assert-MockCalled Get-PartOfWindowsPath -Times 1 {
                    $PartName -eq 'DriveLetter' -and
                    $Path -eq 'path'
                }
            }
        }
        Context 'calls Get-Part for UNC Path' {
            Mock Get-FilePathType {'UNC'}
            Mock Get-PartOfUncPath -Verifiable
            It 'invokes Get-Part function' {
                'path' | ConvertTo-FilePathHashTable

                Assert-MockCalled Get-PartOfUncPath -Times 1 {
                    $PartName -eq 'DomainName' -and
                    $Path -eq 'path'
                }
                Assert-MockCalled Get-PartOfUncPath -Times 1 {
                    $PartName -eq 'Path' -and
                    $Path -eq 'path'
                }
                Assert-MockCalled Get-PartOfUncPath -Times 1 {
                    $PartName -eq 'DriveLetter' -and
                    $Path -eq 'path'
                }
            }
        }
        Context 'Windows' {
            Mock Get-FilePathType {'Windows'}
            Mock Get-PartOfWindowsPath {
                if ( $PartName -eq 'DriveLetter' ) { return 'c' }
                return 'path/fragment'
            }
            It 'returns correct hashtable.' {
                $r = 'path' | ConvertTo-FilePathHashtable

                $r -is [hashtable] | Should be $true
                $r.OriginalString | Should be 'path'
                $r.DriveLetter | Should be 'c'
                $r.LocalPath  | Should be 'path/fragment'
                $r.Segments.Count | Should be 2
                $r.Segments[0] | Should be 'path'
                $r.Segments[1] | Should be 'fragment'
            }
        }
        Context 'Windows DriveLetter Only' {
            Mock Get-FilePathType {'Windows'}
            Mock Get-PartOfWindowsPath {
                if ( $PartName -eq 'DriveLetter' ) { return 'c' }
            }
            It 'returns correct hashtable.' {
                $r = 'path' | ConvertTo-FilePathHashtable

                $r -is [hashtable] | Should be $true
                $r.OriginalString | Should be 'path'
                $r.DriveLetter | Should be 'c'
                $r.LocalPath  | Should beNullOrEmpty
                $r.Segments.Count | Should be 0
            }
        }
        Context 'UNC' {
            Mock Get-FilePathType {'UNC'}
            Mock Get-PartOfUncPath {
                if ( $PartName -eq 'DomainName' )  { return 'domain.name' }
                if ( $PartName -eq 'DriveLetter' ) { return 'c' }
                return 'path/fragment'
            }
            It 'returns correct hashtable.' {
                $r = 'path' | ConvertTo-FilePathHashtable

                $r -is [hashtable] | Should be $true
                $r.OriginalString | Should be 'path'
                $r.DriveLetter | Should be 'c'
                $r.LocalPath  | Should be 'path/fragment'
                $r.Segments.Count | Should be 2
                $r.Segments[0] | Should be 'path'
                $r.Segments[1] | Should be 'fragment'
            }
        }
        Context 'UNC No DriveLetter' {
            Mock Get-FilePathType {'UNC'}
            Mock Get-PartOfUncPath {
                if ( $PartName -eq 'DomainName' )  { return 'domain.name' }
                if ( $PartName -eq 'DriveLetter' ) { return }
                return 'path/fragment'
            }
            It 'returns correct hashtable.' {
                $r = 'path' | ConvertTo-FilePathHashtable

                $r -is [hashtable] | Should be $true
                $r.OriginalString | Should be 'path'
                $r.DriveLetter | Should beNullOrEmpty
                $r.LocalPath  | Should be 'path/fragment'
                $r.Segments.Count | Should be 2
                $r.Segments[0] | Should be 'path'
                $r.Segments[1] | Should be 'fragment'
            }
        }
        Context 'UNC DomainName Only' {
            Mock Get-FilePathType {'UNC'}
            Mock Get-PartOfUncPath {
                if ( $PartName -eq 'DomainName' )  { return 'domain.name' }
            }
            It 'returns correct hashtable.' {
                $r = 'path' | ConvertTo-FilePathHashtable

                $r -is [hashtable] | Should be $true
                $r.OriginalString | Should be 'path'
                $r.DriveLetter | Should beNullOrEmpty
                $r.LocalPath  | Should beNullOrEmpty
                $r.Segments.Count | Should be 0
            }
        }
    }
}
