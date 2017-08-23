$moduleRoot = Split-Path -Path $MyInvocation.MyCommand.Path

@(
    'idemTypes.ps1'
) |
% { . "$($PSCommandPath | Split-Path -Parent)\Functions\$_" }
