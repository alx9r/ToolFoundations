if ( $PSVersionTable.PSVersion.Major -ge 5 )
{
    . "$($PSCommandPath | Split-Path -Parent)\usingModuleTests.ps1"
}
