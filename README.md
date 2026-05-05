# KSP 1.12.5 kOS Mun Tug Crafts

This repo contains stock KSP 1.12.5 craft files built to work with kOS 1.5.1 (no Breaking Ground DLC required).

## Included files

- `craft/kOS-MunTug.craft` — tug-only craft
- `craft/kOS-MunTug-Launcher.craft` — full launcher + tug craft
- `craft/Space Station One.craft` — heavy station-base launcher/platform
- `kos/launch.ks` — Mun tug launcher script for `kOS-MunTug-Launcher.craft`
- `kos/launch_station.ks` — Space Station One boot/launch script with auto-staging and AG9/AG10 launch mode selection
- `kos/set_intercept.ks` — same-body intercept helper for a selected target, intended for follow-on Space Station One rendezvous work

## Install

1. Copy craft files into your save's VAB folder:

   - `craft/kOS-MunTug.craft`
   - `craft/kOS-MunTug-Launcher.craft`
   - `craft/Space Station One.craft`

   to:

   - `KSP/saves/<your-save>/Ships/VAB/`

2. Copy the kOS scripts you plan to use into a kOS-readable volume (for example):

   - `KSP/Ships/Script/launch.ks`
   - `KSP/Ships/Script/launch_station.ks`
   - `KSP/Ships/Script/set_intercept.ks`

   `Space Station One.craft` is configured with boot file `launch_station`, so `launch_station.ks` must be available on the processor's readable volume.

## Use in game

Steam install folder for KSP:

```bash
# macOS
cd ~/Library/Application\ Support/Steam/steamapps/common/Kerbal\ Space\ Program/

# Windows
cd "C:/Program Files (x86)/Steam/steamapps/common/Kerbal Space Program/"
```


1. Start KSP 1.12.5 with stock parts + kOS 1.5.1.
2. Open the VAB and load one of the included craft files.

### Mun tug launcher

Use this flow for `craft/kOS-MunTug-Launcher.craft`.

1. Make sure the kOS CPU has access to `launch.ks`.
2. On the launchpad, open the kOS terminal and run:

   ```
   run launch.
   ```

   If your scripts are stored in `0:/`, run with the full path (for example `runpath("0:/launch").`).

### Space Station One

Use this flow for `craft/Space Station One.craft`.

1. Make sure the kOS CPU can read both `launch_station.ks` and `set_intercept.ks`.
2. The craft's boot file is `launch_station`, so the launch script should preload automatically when the vessel becomes active.
3. On the pad, trigger:

   - `AG9` for `KERBIN` mode, which launches to parking orbit for station assembly
   - `AG10` for `MUN` mode, which continues from parking orbit into the Mun transfer profile

4. If the boot file is unavailable or you want to start it manually, run:

   ```
   run launch_station.
   ```

5. Once you are in orbit and have selected a target around the same body, run:

   ```
   run set_intercept.
   ```

   `set_intercept.ks` expects a target to already be selected. It creates and executes a transfer maneuver, then performs simple refinement burns for same-body intercept work.

If your scripts are stored in `0:/`, run with full paths instead (for example `runpath("0:/launch_station").` and `runpath("0:/set_intercept").`).

## Space Station One notes

- `craft/Space Station One.craft` now uses `vesselType = Probe` and kOS boot file `launch_station`.
- `launch_station.ks` is the intended launch profile for `Space Station One`; `launch.ks` remains the Mun tug launcher script.
- `set_intercept.ks` is the intended follow-on script for Space Station One rendezvous/intercept operations after reaching orbit.
- The craft currently uses large docking ports, while `kOS-MunTug` uses a standard docking port.
- Add a docking adapter path in the VAB (or a standard port on the station) before mixed-diameter docking operations.
- Add dedicated comms relay hardware and RCS translation authority in the VAB if this vehicle will act as an autonomous station assembly hub.
