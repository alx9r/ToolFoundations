@(
    'idemTypes.ps1'
) |
% { . "$($PSCommandPath | Split-Path -Parent)\$_" }
