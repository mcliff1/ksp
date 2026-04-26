# KSP 1.12.5 kOS Mun Tug Crafts

This repo contains stock KSP 1.12.5 craft files built to work with kOS 1.5.1 (no Breaking Ground DLC required).

## Included files

- `craft/kOS-MunTug.craft` — tug-only craft
- `craft/kOS-MunTug-Launcher.craft` — full launcher + tug craft
- `craft/Space Station One.craft` — heavy station-base launcher/platform
- `kos/launch.ks` — example kOS launch script
- `kos/launch_station.ks` — Space Station One launch script with auto-staging and optional Mun transfer mode

## Install

1. Copy craft files into your save's VAB folder:

   - `craft/kOS-MunTug.craft`
   - `craft/kOS-MunTug-Launcher.craft`

   to:

   - `KSP/saves/<your-save>/Ships/VAB/`

2. Copy `kos/launch.ks` into a kOS-readable volume (for example):

   - `KSP/Ships/Script/launch.ks`

   For Space Station One also copy:

   - `KSP/Ships/Script/launch_station.ks`

## Use in game

this is home folder

```bash
cd ~/Library/Application\ Support/Steam/steamapps/common/Kerbal\ Space\ Program/
```


1. Start KSP 1.12.5 with stock parts + kOS 1.5.1.
2. Open the VAB and load one of the included craft files.
3. Make sure the kOS CPU has access to `launch.ks`.
4. On the launchpad, open the kOS terminal and run:

   ```
   run launch.
   ```

If your scripts are stored in `0:/`, run with the full path (for example `runpath("0:/launch").`).

For Space Station One, run:

```
run launch_station.
```

`launch_station.ks` defaults to `KERBIN` mode (park in LKO for assembly).
Set `targetMode` to `"MUN"` in the script for a Mun transfer profile.

## Space Station One notes

- `craft/Space Station One.craft` now uses `vesselType = Probe` and kOS boot file `launch_station`.
- The craft currently uses large docking ports, while `kOS-MunTug` uses a standard docking port.
- Add a docking adapter path in the VAB (or a standard port on the station) before mixed-diameter docking operations.
- Add dedicated comms relay hardware and RCS translation authority in the VAB if this vehicle will act as an autonomous station assembly hub.
