$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Exe = Join-Path $Root 'build\whitehole.exe'

if (-not (Test-Path $Exe)) {
    & (Join-Path $Root 'build.ps1')
}

Push-Location $Root
try {
    & $Exe
}
finally {
    Pop-Location
}

