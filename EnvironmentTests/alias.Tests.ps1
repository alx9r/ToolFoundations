$guid = [guid]::NewGuid().Guid

Describe 'alias: drive' {
    Context 'folders' {
        It 'New-Item throws' {
            { New-Item -Path alias: -Name folder -ItemType Directory -ErrorAction Stop } |
                Should throw
        }
        It 'New-Item "succeeds"...' {
            New-Item -Path alias: -Name folder -Value 'value' -ItemType Directory -ErrorAction Stop 
        }
        It '...but no item is created.' {
            $r = Get-ChildItem -Path alias: -Recurse |
                ? { $_.Name -in 'folder','value' }
            $r | Should beNullOrEmpty
        }
    }
}
Describe 'altering aliases' {
    Context 'rename local alias' {
        It 'works' {
            Set-Alias someName someCommand
            Get-Alias someName | Should not beNullOrEmpty
            Rename-Item alias:\someName someOtherName
            Get-Alias someName -ea si | Should beNullOrEmpty
            Get-Alias someOtherName | Should not beNullOrEmpty
        }
    }
    Context 'rename Global AllScope alias' {
        It 'create alias' {
            Set-Alias someName someCommand -Option AllScope -Scope Global
        }
        It 'exists in this scope' {
            Get-Alias someName | Should not beNullOrEmpty
        }
        It 'renaming works in local scope' {
            Rename-Item Alias:\someName someOtherName
            Get-Alias someName -ea si | Should beNullOrEmpty
            Get-Alias someOtherName | Should not beNullOrEmpty
        }
        It 'the old name is gone in this scope...' {
            Get-Alias someName -ea si | Should beNullOrEmpty
        }
        It '...but so is the new name.' {
            Get-Alias someOtherName -ea si | Should beNullOrEmpty
        }
    }
}
Describe 'removing aliases' {
    Context 'Global AllScope created outside module removed from inside module' {
        It 'create module' {
            New-Module {
                function f { Get-Alias someName -ea si }
                function g { Remove-Item alias:\someName -ErrorAction Stop }
                function h { Rename-Item alias:\someName someOtherName -ErrorAction Stop }
                function j { Remove-Item alias:\someName -Force -ErrorAction Stop }
            }
        }
        It 'create alias' {
            Set-Alias someName someCommand -Option AllScope -Scope Global
        }
        It 'exists in this scope' {
            Get-Alias someName | Should not beNullOrEmpty
        }
        It 'exists in the module''s scope' {
            f | Should not beNullOrEmpty
        }
        It 'removing from the module''s scope seems to succeed...' {
            g
        }
        It '... but it still exists in this scope...' {
            Get-Alias someName -ea Stop | Should not beNullOrEmpty
        }
        It '...and it still exists in the module''s scope' {
            f | Should not beNullOrEmpty
        }
        It 'renaming from inside module''s scope seems to succeed...' {
            h
        }
        It '... but it still exists in this scope...' {
            Get-Alias someName -ea Stop | Should not beNullOrEmpty
        }
        It '...and it still exists in the module''s scope' {
            f | Should not beNullOrEmpty
        }
        It 'removing item with force from inside module''s scope seems to succeed...' {
            j
        }
        It '... but it still exists in this scope...' {
            Get-Alias someName -ea Stop | Should not beNullOrEmpty
        }
        It '...and it still exists in the module''s scope' {
            f | Should not beNullOrEmpty
        }
        It 'cleanup' {
            Remove-Item function:\f
            Remove-Item function:\g
            Remove-Item function:\h
        }
    }
}
Describe 'override alias' {
    Context 'Global AllScope created outside module overridden inside module' {
        $h = @{}
        It 'create module' {
            $h.Module = New-Module {
                function someCommand { 'someCommand called' }
                function anotherCommand { 'anotherCommand called' }
                function f { Get-Alias someName }
                function g { Set-Alias someName anotherCommand -Force -ErrorAction Stop }
                function h { Remove-Item alias:\someName -ErrorAction Stop }
                function j {
                    Remove-Item alias:\someName -ErrorAction Stop
                    Set-Alias someName anotherCommand -ErrorAction Stop
                }
                function k {
                    Remove-Item alias:\someName -ErrorAction Stop
                    Set-Alias someName anotherCommand -ErrorAction Stop
                    Get-Alias someName
                }
                function l {
                    Remove-Item alias:\someName -ErrorAction Stop
                    Set-Alias someName anotherCommand -ErrorAction Stop
                    Get-Alias someName
                    someName
                }
                function m {
                    someName
                }
                function n {
                    Remove-Item alias:\someName -ErrorAction Stop
                    Set-Alias someName anotherCommand -ErrorAction Stop
                    Get-Alias someName
                    m
                }
                function p {
                    Remove-Item alias:\someName -ErrorAction Stop
                    Set-Alias someName anotherCommand -ErrorAction Stop
                    Get-Alias someName
                    $args.Invoke()
                }
            }
        }
        It 'create alias' {
            Set-Alias someName someCommand -Option AllScope -Scope Global
        }
        It 'exists in this scope' {
            Get-Alias someName | Should not beNullOrEmpty
        }
        It 'exists in the module''s scope' {
            f | Should not beNullOrEmpty
        }
        It 'setting the alias to a different definition inside the module throws' {
            { g } |
                Should throw 'The AllScope option cannot be removed'
        }
        It 'removing alias inside module...' {
            h
        }
        It '...then creating a new alias with the same inside module throws' {
            { g } |
                Should throw 'The AllScope option cannot be removed'
        }
        It 'removing and creating new alias in one call seems to succeed...' {
            j
        }
        It '...but the original alias still exists in this scope...' {
            $r = Get-Alias someName
            $r.Definition | Should be someCommand
        }
        It '...and the original alias still exists in the module''s scope' {
            $r = f
            $r.Definition | Should be someCommand
        }
        It 'removing, creating, and getting alias in one call seems to succeed...' {
            $r = k
            $r.Definition | Should be anotherCommand
        }
        It '...but the original alias still exists in this scope...' {
            $r = Get-Alias someName
            $r.Definition | Should be someCommand
        }
        It '...and the original alias still exists in the module''s scope on another call.' {
            $r = f
            $r.Definition | Should be someCommand
        }
        It 'removing, creating, getting, and using alias in one call succeeds...' {
            $r = l
            $r[0].Definition | Should be 'anotherCommand'
            $r[1] | Should be 'anotherCommand called'
        }
        It '...even when alias is used by a child scope...' {
            $r = n
            $r[0].Definition | Should be 'anotherCommand'
            $r[1] | Should be 'anotherCommand called'
        }
        It '...even when the child scope is a scriptblock...' {
            $r = p $h.Module.NewBoundScriptBlock( { someName } )
            $r[0].Definition | Should be 'anotherCommand'
            $r[1] | Should be 'anotherCommand called'
        }
        It '...and the original alias still exists in this scope' {
            $r = Get-Alias someName
            $r.Definition | Should be 'someCommand'
        }
        It 'cleanup' {
            Remove-Item function:\f
            Remove-Item function:\g
            Remove-Item function:\h
            Remove-Item function:\j
            Remove-Item function:\k
            Remove-Item function:\l
            Remove-Item function:\m
            Remove-Item function:\n
            Remove-Item function:\p
            Remove-Item function:\someCommand
            Remove-Item function:\anotherCommand
        }
    }
}
Remove-Item Alias:\someName
