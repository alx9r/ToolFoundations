$path = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
if ( (Get-Module Pester).Version -lt '4.0.0' )
{
    . "$path\pester3InModuleScopeTests.ps1"
}
else
{
    . "$path\pester4InModuleScopeTests.ps1"
}
