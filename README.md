# KSP 1.12.5 kOS Mun Tug Crafts

This repo contains stock KSP 1.12.5 craft files built to work with kOS 1.5.1 (no Breaking Ground DLC required).

## Included files

- `craft/kOS-MunTug.craft` — tug-only craft
- `craft/kOS-MunTug-Launcher.craft` — full launcher + tug craft
- `craft/Space Station One.craft` — heavy station-base launcher/platform
- `craft/SS1 Mark2.craft` — Space Station One variant with stiffer radial booster mounts and extra first-stage propellant
- `kos/launch.ks` — Mun tug launcher script for `kOS-MunTug-Launcher.craft`
- `kos/ss1/launch_station.ks` — Space Station One boot/launch script with auto-staging and AG9/AG10 launch mode selection
- `kos/ss1/set_intercept.ks` — same-body intercept helper for a selected target, intended for follow-on Space Station One rendezvous work
- `kos/ss1/match_velocity.ks` — relative-velocity kill helper for same-body rendezvous after intercept
- `kos/launch_station.ks`, `kos/set_intercept.ks`, `kos/match_velocity.ks` — compatibility wrappers that forward to `kos/ss1/`

## Install

1. Copy craft files into your save's VAB folder:

   - `craft/kOS-MunTug.craft`
   - `craft/kOS-MunTug-Launcher.craft`
   - `craft/Space Station One.craft`
   - `craft/SS1 Mark2.craft`

   to:

   - `KSP/saves/<your-save>/Ships/VAB/`

2. Copy the kOS scripts you plan to use into a kOS-readable volume (for example):

   - `KSP/Ships/Script/launch.ks`
   - `KSP/Ships/Script/launch_station.ks`
   - `KSP/Ships/Script/set_intercept.ks`
   - `KSP/Ships/Script/match_velocity.ks`
   - `KSP/Ships/Script/ss1/launch_station.ks`
   - `KSP/Ships/Script/ss1/set_intercept.ks`
   - `KSP/Ships/Script/ss1/match_velocity.ks`

   `Space Station One.craft` is configured with boot file `launch_station`, so `launch_station.ks` must still be available on the processor's readable volume. The root SS1 scripts are wrappers, so copy the `ss1/` subfolder as well.

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

If the original launcher feels too flexible on ascent, `craft/SS1 Mark2.craft` is a heavier-launch variant with stiffer radial booster attachments and more side-booster propellant for an easier climb to LKO.

1. Make sure the kOS CPU can read `launch_station.ks`, `set_intercept.ks`, `match_velocity.ks`, and the `ss1/` subfolder versions they forward to.
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

   `set_intercept.ks` expects a target to already be selected. It waits for the required same-body phase angle, then executes a direct Hohmann-style burn using the newer MunTug intercept logic.

   For a faster/tighter setup that spends extra fuel before docking, run:

   ```
   run set_intercept("DOCK").
   ```

   With full-path invocation, pass the option as a second argument:

   ```
   runpath("0:/set_intercept", "DOCK").
   ```

   `DOCK` mode tightens phase tolerance, applies a modest overburn, and performs a short trim pass to set up a closer rendezvous for a follow-on docking procedure.

6. Near closest approach, run:

   ```
   run match_velocity.
   ```

   `match_velocity.ks` points to relative retrograde and burns down relative speed to help convert the intercept into a rendezvous.

7. Final approach and docking should be done manually with low-speed inputs (or your preferred docking script).

If your scripts are stored in `0:/`, the existing root commands still work as long as the `ss1/` subfolder is present. The direct implementation paths are `runpath("0:/ss1/launch_station").`, `runpath("0:/ss1/set_intercept", "DOCK").`, and `runpath("0:/ss1/match_velocity").`.

`set_intercept.ks` and `match_velocity.ks` are stage-safe: neither script calls `stage`.

## Static checks

Run the local static checker before in-game testing:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\check-kos-static.ps1
```

What it checks:

- brace-balance sanity across all `kos/**/*.ks` files (legacy bare `}` style is warned, not failed)
- helper-script stage safety (no direct `stage` call) for `kos/ss1/set_intercept.ks` and `kos/ss1/match_velocity.ks`
- helper-script target guards (`if not hastarget` and same-body check)

## Space Station One notes

- `craft/Space Station One.craft` now uses `vesselType = Probe` and kOS boot file `launch_station`.
- `kos/ss1/launch_station.ks` is the intended launch profile for `Space Station One`; `launch.ks` remains the Mun tug launcher script.
- `kos/ss1/set_intercept.ks` is the intended follow-on script for Space Station One rendezvous/intercept operations after reaching orbit.
- `kos/ss1/match_velocity.ks` is the intended follow-on helper after `set_intercept.ks` to reduce relative speed at closest approach.
- The root SS1 scripts are compatibility wrappers so existing boot files and `run` commands do not need to change.
- The craft currently uses large docking ports, while `kOS-MunTug` uses a standard docking port.
- Add a docking adapter path in the VAB (or a standard port on the station) before mixed-diameter docking operations.
- Add dedicated comms relay hardware and RCS translation authority in the VAB if this vehicle will act as an autonomous station assembly hub.
