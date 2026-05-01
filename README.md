# WhiteHole.asm

An experimental white hole visualization written with a Windows x64 Assembly
host and a full OpenGL shader chain.

The executable is written in NASM. It creates a Win32/WGL window, loads GLSL
shaders from disk, and renders a theoretical Schwarzschild white hole in real
time using ray bending, procedural emission, an equatorial disk, and bipolar
jets.

## GitHub Codespaces / Mobile Preview

The original Assembly host is Windows/WGL-specific, so it does not run natively
inside Linux-based GitHub Codespaces. For mobile and Codespaces use, this repo
also includes a browser WebGL preview in `web/`.

Open directly in Codespaces:

- https://codespaces.new/Lamarq7eYT/WhiteHolewithASM?quickstart=1

Then run:

```bash
./run-web.sh
```

Codespaces will forward port `8000`. Open the forwarded preview in the browser.
On mobile, use drag to orbit, pinch/wheel to zoom, and double tap to reset.

## Inspiration

This project was inspired by Kavan's black hole renderer:

- https://github.com/kavan010/black_hole

That project renders a black hole with C++ and OpenGL. This repository explores
a related idea from the opposite causal boundary: a white hole, driven by an
Assembly host and GLSL shaders.

## Physics Model

A white hole is not modeled here as antigravity. Outside the horizon, a
Schwarzschild white hole has the same exterior geometry as a Schwarzschild black
hole with the same mass. It still bends light, creates gravitational lensing,
and has a photon sphere.

The difference is causal. A black hole allows trajectories to enter the horizon
but not escape. A classical white hole is the time reverse: it emits outward and
does not allow exterior trajectories to cross inward into the classical
interior.

The fragment shader traces rays through the optical form of the Schwarzschild
metric in isotropic coordinates:

```text
n(rho) = (1 + rs / 4rho)^3 / (1 - rs / 4rho)
dI/ds = grad(log n) - I (I . grad(log n))
```

This bends light in the exterior region. When a traced ray reaches the horizon
neighborhood, the shader applies a white-hole boundary condition: intense
outward emission rather than absorption.

The renderer also emphasizes the isotropic-coordinate photon sphere,
`rho ~= 0.933 rs`, so the lensing ring is visible.

## Visual Direction

The visual style is intentionally cinematic:

- white/cyan core
- bright cyan rim
- wide turbulent equatorial disk
- animated procedural density ridges
- bipolar jets with twist, edge noise, and particles
- starfield lensing and ghosted caustic arcs
- subtle temporal flicker and chromatic glow

These artistic emission elements sit on top of the ray-bent Schwarzschild
exterior. The result is a technical demo rather than an astrophysical
prediction; classical white holes remain theoretical and unstable objects.

## Controls

Desktop Assembly version:

- Drag with the left mouse button: orbit the 3D camera
- Mouse wheel: zoom in/out
- Arrow keys: fine-tune projection center for your monitor/DPI
- `C`: return to the mathematical projection center
- `R`: reset camera, zoom, and projection center
- `Esc`: exit

Browser WebGL preview:

- Drag: orbit the camera
- Pinch / mouse wheel: zoom in/out
- Double tap / double click: reset camera

## Build

The portable toolchain used during development was stored on `F:\`:

- `F:\tools\winlibs\mingw64\bin\nasm.exe`
- `F:\tools\winlibs\mingw64\bin\gcc.exe`

Build:

```powershell
.\build.ps1
```

Run:

```powershell
.\run.ps1
```

## Project Layout

- `src/whitehole.asm`: Win32/WGL host in NASM x64 Assembly
- `shaders/whitehole.vert`: vertex shader
- `shaders/whitehole.geom`: geometry shader
- `shaders/whitehole.frag`: ray bending and white-hole visual simulation
- `web/`: browser WebGL preview for Codespaces and mobile browsers
- `.devcontainer/devcontainer.json`: GitHub Codespaces configuration
- `setup.sh`: Codespaces setup note/script
- `run-web.sh`: serves the WebGL preview on port `8000`
- `build.ps1`: builds the executable
- `run.ps1`: builds if needed and runs the demo
