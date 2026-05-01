$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path

function Find-Tool {
    param(
        [Parameter(Mandatory = $true)] [string] $Name,
        [string[]] $ExtraPaths = @()
    )

    foreach ($Path in $ExtraPaths) {
        if ($Path -and (Test-Path $Path)) {
            return $Path
        }
    }

    $Command = Get-Command $Name -ErrorAction SilentlyContinue
    if ($Command) {
        return $Command.Source
    }

    throw "$Name not found. Install it and make sure it is available in PATH. For example: choco install nasm mingw -y"
}

$KnownToolRoots = @(
    'F:\tools\winlibs\mingw64\bin',
    'C:\tools\winlibs\mingw64\bin',
    'C:\msys64\mingw64\bin',
    'C:\ProgramData\chocolatey\bin'
)

$NasmCandidates = @()
$GccCandidates = @()
foreach ($ToolRoot in $KnownToolRoots) {
    $NasmCandidates += (Join-Path $ToolRoot 'nasm.exe')
    $GccCandidates += (Join-Path $ToolRoot 'gcc.exe')
}

$Nasm = Find-Tool 'nasm.exe' $NasmCandidates
$Gcc = Find-Tool 'gcc.exe' $GccCandidates

Write-Host "Using NASM: $Nasm"
Write-Host "Using GCC:  $Gcc"

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
