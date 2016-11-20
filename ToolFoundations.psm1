
# dot source all of the other .ps1 files
$moduleRoot = Split-Path -Path $MyInvocation.MyCommand.Path

# but do the type files first
$typeFiles = "$moduleRoot\Functions\*Types.ps1"
$otherFiles = "$moduleRoot\Functions\*.ps1" | ? {$typeFiles -notcontains $_}
@($typeFiles)+@($otherFiles) |
    Resolve-Path |
    Where-Object { -not ($_.ProviderPath.ToLower().Contains("tests.")) } |
    ForEach-Object { . $_.ProviderPath }

# Export all the functions and module members here.
# Use the module manifest to filter exported module members.
Export-ModuleMember -Function * -Alias *