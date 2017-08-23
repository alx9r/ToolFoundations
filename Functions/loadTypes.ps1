$moduleRoot = Split-Path -Path $MyInvocation.MyCommand.Path

@(
    'idemTypes.ps1'
) |
% { . "$($moduleRoot | Split-Path -Parent)\Functions\$_" }
