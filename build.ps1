$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$ToolRoot = 'F:\tools\winlibs\mingw64\bin'
$Nasm = Join-Path $ToolRoot 'nasm.exe'
$Gcc = Join-Path $ToolRoot 'gcc.exe'

if (-not (Test-Path $Nasm)) {
    throw "NASM not found at $Nasm"
}

if (-not (Test-Path $Gcc)) {
    throw "GCC not found at $Gcc"
}

$BuildDir = Join-Path $Root 'build'
New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null

$Obj = Join-Path $BuildDir 'whitehole.obj'
$Exe = Join-Path $BuildDir 'whitehole.exe'

& $Nasm -f win64 (Join-Path $Root 'src\whitehole.asm') -o $Obj
if ($LASTEXITCODE -ne 0) {
    throw "NASM failed with exit code $LASTEXITCODE"
}

& $Gcc $Obj -o $Exe -mwindows -lopengl32 -lgdi32 -luser32 -lkernel32
if ($LASTEXITCODE -ne 0) {
    throw "Link failed with exit code $LASTEXITCODE"
}

Write-Host "Build OK: $Exe"
