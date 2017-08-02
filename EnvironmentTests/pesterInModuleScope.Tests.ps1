if ( (Get-Module Pester).Version -lt '4.0.0' )
{
    . "$PSScriptRoot\pester3InModuleScopeTests.ps1"
}
else
{
    . "$PSScriptRoot\pester4InModuleScopeTests.ps1"
}
