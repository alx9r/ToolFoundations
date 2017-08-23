
$moduleRoot = Split-Path -Path $MyInvocation.MyCommand.Path

# Dot source the type files...
. "$moduleRoot\Functions\LoadTypes.ps1"

# ...and then the remaining .ps1 files
"$moduleRoot\Functions\*.ps1",
"$moduleRoot\dotNetTypes\*.ps1" |
    Get-Item |
    ? {
        $_.Name -notmatch 'Tests\.ps1$' -and
        $_.Name -notmatch 'Types?\.ps1$'
    } |
    % { . $_.FullName }

# Export all the functions and module members here.
# Use the module manifest to filter exported module members.
Export-ModuleMember -Function * -Alias *