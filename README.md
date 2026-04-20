# ksp

## Install

1. Copy the craft files from `craft/` into:
   - `KSP/saves/<save>/Ships/VAB/`
2. Copy `kos/launch.ks` into your vessel kOS volume (for example via Archive or local volume as preferred).

## Mod requirements

- [kOS](https://github.com/KSP-KOS/KOS) `1.5.1`

## Included craft

- `craft/kOS-MunTug.craft` - tug-only craft.
- `craft/kOS-MunTug-Launcher.craft` - full launcher + tug stack.

## Basic usage

1. In KSP VAB, load `kOS-MunTug-Launcher` for launch to orbit.
2. Start flight and run `launch.ks` from the kOS CPU.
3. The script performs a basic ascent and circularization to about 80 km.
4. After circularization, use the tug stage for transfer and rendezvous operations.
