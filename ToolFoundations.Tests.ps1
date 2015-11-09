# This file is derived, in part, from the Pester project.  https://github.com/pester/Pester
Import-Module ToolFoundations

$here = Split-Path -Parent $MyInvocation.MyCommand.Path

$manifestPath   = "$here\ToolFoundations.psd1"
$changeLogPath = "$here\CHANGELOG.md"

Describe "manifest and changelog" {
    $script:manifest = $null
    It "has a valid manifest" {
        {
            $script:manifest = Test-ModuleManifest -Path $manifestPath -ErrorAction Stop -WarningAction SilentlyContinue
        } | Should Not Throw
    }

    It "has a valid name in the manifest" {
        $script:manifest.Name | Should Be ToolFoundations
    }

    It "has a valid guid in the manifest" {
        $script:manifest.Guid | Should Be 'c609520d-f4ac-416a-8ac4-ebfc8dffd664'
    }

    It "has a valid version in the manifest" {
        $script:manifest.Version -as [Version] | Should Not BeNullOrEmpty
    }

    $script:changelogVersion = $null
    It "has a valid version in the changelog" {

        foreach ($line in (Get-Content $changeLogPath))
        {
            if ($line -match "^\D*(?<Version>(\d+\.){1,3}\d+)")
            {
                $script:changelogVersion = $matches.Version
                break
            }
        }
        $script:changelogVersion                | Should Not BeNullOrEmpty
        $script:changelogVersion -as [Version]  | Should Not BeNullOrEmpty
    }

    if ( (Get-Content $changeLogPath)[0] -ne '## Unreleased' )
    {
        It "then changelog and manifest versions are the same" {
            $script:changelogVersion -as [Version] | Should be ( $script:manifest.Version -as [Version] )
        }

        if (Get-Command git.exe -ErrorAction SilentlyContinue) {
            $script:tagVersion = $null
            It "is tagged with a valid version" {
                $thisCommit = git.exe log --decorate --oneline HEAD~1..HEAD

                $mask = 'tag:\s*(?<version>[0-9]*\.[0-9]*\.[0-9]*)'
                $script:tagVersion = [regex]::Match($thisCommit,$mask).Groups['version'].Value

                $script:tagVersion                  | Should Not BeNullOrEmpty
                $script:tagVersion -as [Version]    | Should Not BeNullOrEmpty
            }

            It "all versions are the same" {
                $script:changelogVersion -as [Version] | Should be ( $script:manifest.Version -as [Version] )
                $script:manifest.Version -as [Version] | Should be ( $script:tagVersion -as [Version] )
            }

        }
    }
}

Describe 'Style rules' {
    $moduleRoot = (Get-Module ToolFoundations).ModuleBase

    $files = @(
        Get-ChildItem $moduleRoot -Include *.ps1,*.psm1
        Get-ChildItem $moduleRoot\Functions -Include *.ps1,*.psm1 -Recurse
        Get-ChildItem $moduleRoot\EnvironmentTests -Include *.ps1,*.psm1 -Recurse
    )

    It 'Source files contain no trailing whitespace' {
        $badLines = @(
            foreach ($file in $files)
            {
                $lines = [System.IO.File]::ReadAllLines($file.FullName)
                $lineCount = $lines.Count

                for ($i = 0; $i -lt $lineCount; $i++)
                {
                    if ($lines[$i] -match '\s+$')
                    {
                        'File: {0}, Line: {1}' -f $file.FullName, ($i + 1)
                    }
                }
            }
        )

        if ($badLines.Count -gt 0)
        {
            throw "The following $($badLines.Count) lines contain trailing whitespace: `r`n`r`n$($badLines -join "`r`n")"
        }
    }

    It 'Source Files all end with a newline' {
        $badFiles = @(
            foreach ($file in $files)
            {
                $string = [System.IO.File]::ReadAllText($file.FullName)
                if ($string.Length -gt 0 -and $string[-1] -ne "`n")
                {
                    $file.FullName
                }
            }
        )

        if ($badFiles.Count -gt 0)
        {
            throw "The following files do not end with a newline: `r`n`r`n$($badFiles -join "`r`n")"
        }
    }
    It 'doesn''t contain new operators.' {
        $badLines = @(
            foreach ($file in $files)
            {
                $lines = [System.IO.File]::ReadAllLines($file.FullName)
                $lineCount = $lines.Count

                for ($i = 0; $i -lt $lineCount; $i++)
                {
                    if ($lines[$i] -match '( -in | -notin | -shr | -shl )')
                    {
                        'File: {0}, Line: {1}' -f $file.FullName, ($i + 1)
                    }
                }
            }
        )

        if ($badLines.Count -gt 0)
        {
            throw "The following $($badLines.Count) lines contain operators introduced after PowerShell 2.0 (e.g. in, notin, shr, shl)  : `r`n`r`n$($badLines -join "`r`n")"
        }
    }
}
