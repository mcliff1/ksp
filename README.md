# KSP 1.12.5 kOS Mun Tug Crafts

This repo contains stock KSP 1.12.5 craft files built to work with kOS 1.5.1 (no Breaking Ground DLC required).

## Included files

- `craft/kOS-MunTug.craft` — tug-only craft
- `craft/kOS-MunTug-Launcher.craft` — full launcher + tug craft
- `craft/Space Station One.craft` — heavy station-base launcher/platform
- `craft/SS1 Mark2.craft` — Space Station One variant with stiffer radial booster mounts and extra first-stage propellant
- `kos/launch.ks` — Mun tug launcher script for `kOS-MunTug-Launcher.craft`
- `kos/ss1/launch_station.ks` — Space Station One boot/launch script with auto-staging and AG9/AG10 launch mode selection
- `kos/ss1/intercept.ks` — same-body intercept + encounter-trim + velocity-match helper for a selected target
- `kos/ss1/intercept2.ks` — docking-first intercept workflow with explicit maneuver-step countdown/status output
- `kos/ss1/match_velocity.ks` — relative-velocity kill helper for same-body rendezvous after intercept
- `kos/launch_station.ks`, `kos/intercept.ks`, `kos/intercept2.ks`, `kos/match_velocity.ks` — primary root entrypoints that forward to `kos/ss1/`
- `kos/set_intercept.ks` — compatibility alias that forwards to `kos/intercept.ks`

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
   - `KSP/Ships/Script/intercept.ks`
   - `KSP/Ships/Script/intercept2.ks`
   - `KSP/Ships/Script/set_intercept.ks`
   - `KSP/Ships/Script/match_velocity.ks`
   - `KSP/Ships/Script/ss1/launch_station.ks`
   - `KSP/Ships/Script/ss1/intercept.ks`
   - `KSP/Ships/Script/ss1/intercept2.ks`
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

1. Make sure the kOS CPU can read `launch_station.ks`, `intercept.ks`, `match_velocity.ks`, and the `ss1/` subfolder versions they forward to.
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
   run intercept.
   ```

   For the docking-first experimental workflow with explicit per-step countdown/status messaging, run:

   ```
   run intercept2.
   ```

   `intercept.ks` expects a target to already be selected. It runs a full rendezvous setup sequence: phase alignment, transfer burn, coast with warp to encounter, encounter trim, and built-in velocity matching.

   For a faster/tighter setup that spends extra fuel before docking, run:

   ```
   run intercept("DOCK").
   ```

   With full-path invocation, pass the option as a second argument:

   ```
   runpath("0:/intercept", "DOCK").
   ```

   `DOCK` mode tightens phase tolerance, applies a modest overburn, and uses stronger trim settings before velocity match.

   If you want transfer/intercept only (no built-in velocity match), run:

   ```
   run intercept("INTERCEPT").
   ```

6. Optional: run manual velocity match script if you skipped built-in matching:

   ```
   run match_velocity.
   ```

   `match_velocity.ks` points to relative retrograde and burns down relative speed. This is primarily useful when you run `intercept("INTERCEPT")`.

7. Final approach and docking should be done manually with low-speed inputs (or your preferred docking script).

If your scripts are stored in `0:/`, the existing root commands still work as long as the `ss1/` subfolder is present. The direct implementation paths are `runpath("0:/ss1/launch_station").`, `runpath("0:/ss1/intercept", "DOCK").`, and `runpath("0:/ss1/match_velocity").`.

`intercept.ks` and `match_velocity.ks` are stage-safe: neither script calls `stage`.

### SS1 intercept strategy draft (for `intercept2` review)

Proposed strategy for the new `kos/ss1/intercept2.ks` workflow:

1. Validate preconditions before doing anything dynamic:
   - target is selected
   - target orbits the same body
   - craft has available thrust
2. Align orbital plane to target at AN/DN before phasing:
   - compute relative inclination and AN/DN opportunity
   - perform normal/antinormal correction burn near AN or DN
   - require small residual inclination (for example <= 0.2 deg) before continuing
3. Compute transfer geometry from current and target orbital radii:
   - transfer time from Hohmann half-orbit
   - required phase angle at burn time
   - compute the upcoming maneuver windows (plane-fix burn, transfer burn, encounter trim)
4. Enter coarse phase wait with warp enabled:
   - monitor phase error continuously
   - drop warp as error enters a small window
5. Perform fine phase lock at warp 0:
   - wait for a tighter error threshold than the coarse window
   - timeout with clear status if convergence takes too long
6. Execute primary transfer burn:
   - align to prograde/retrograde based on computed dV sign
   - throttle taper near burn completion
7. Coast toward encounter with controlled warp:
   - use target range trend to detect closest-approach pass
   - log why warp exits (distance threshold vs passed closest approach)
8. Apply encounter trim before closest approach:
   - estimate trim dV from live phase/range error
   - clamp trim burn to safe limits per mode
9. Run relative-velocity match as part of the same script by default:
   - align to relative retrograde
   - burn down to mode-specific terminal relative speed
10. Keep docking-first behavior explicit:
   - `intercept2` should default to docking-grade tolerances and include velocity match
   - keep intercept-only behavior in `intercept.ks`, not `intercept2.ks`
11. Always leave the ship in a safe control state on exit/abort:
   - throttle zero
   - steering/throttle locks released
   - warp reset to 1
   - no staging commands in helper logic

Execution behavior requirements for `intercept2`:

1. Every maneuver step should follow a consistent pattern:
   - calculate target condition and burn estimate
   - print what is planned next and why
   - warp ahead toward execution window
   - drop warp with margin
   - execute burn with throttle taper
   - print completion and next step
2. During all waits, print live status lines whenever possible:
   - current step name (for example `Plane Align`, `Transfer Burn`, `Encounter Trim`, `Velocity Match`)
   - what condition is being waited on
   - countdown or remaining error (time, angle, range, or relative speed)
3. Keep countdowns operator-friendly:
   - show coarse updates during long warps
   - increase update frequency near execution windows
   - print explicit "warp exit reason" whenever warp is disengaged
4. If a wait or convergence step times out:
   - print the timeout reason and last measured values
   - move to safe cleanup state (throttle 0, unlock controls, warp 1)

Review goals for `intercept2`:

- reduce closest-approach miss distance versus current `intercept.ks`
- reduce relative inclination early (AN/DN correction) before transfer-phase logic
- avoid unsupported kOS suffixes/properties
- keep runtime messaging clear enough to debug in-flight decisions

### `intercept2` display layout

`intercept2` uses fixed-row display positions so live status lines update in place without scrolling. Rows above 8 are reserved for fixed-position status; scrolling print output appears above row 8.

| Row | Content |
|-----|---------|
| 8   | Plane burn countdown (seconds remaining to timed normal/antinormal burn) |
| 9   | Active burn status — direction (prograde/retrograde) and delta-v (m/s) |
| 10  | Phase window status — phase error (deg), drift rate (deg/s), ETA to window (min), current warp level; also used for fine phase lock error |
| 11  | Phase nudge status — nudge index, delta-v applied (m/s), current phase error (deg) |
| 12  | Plane alignment warp countdown (seconds to node) |
| 13  | Plane burn lead countdown (seconds to burn start) |
| 14  | Coast status — current range to target (m) |
| 15  | Encounter trim wait — current range to target (m) |
| 16  | Velocity match approach wait — current range to target (m) |
| 17  | Velocity match burn — relative speed (m/s) |

Scrolling (non-fixed) print lines appear above row 8 and log step transitions, burn plans, warp exit reasons, completion messages, and abort messages.

## Static checks

Run the local static checker before in-game testing:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\check-kos-static.ps1
```

What it checks:

- brace-balance sanity across all `kos/**/*.ks` files (legacy bare `}` style is warned, not failed)
- helper-script stage safety (no direct `stage` call) for `kos/ss1/intercept.ks` and `kos/ss1/match_velocity.ks`
- helper-script target guards (`if not hastarget` and same-body check)

## Space Station One notes

- `craft/Space Station One.craft` now uses `vesselType = Probe` and kOS boot file `launch_station`.
- `kos/ss1/launch_station.ks` is the intended launch profile for `Space Station One`; `launch.ks` remains the Mun tug launcher script.
- `kos/ss1/intercept.ks` is the intended follow-on script for Space Station One rendezvous/intercept operations after reaching orbit.
- `kos/ss1/match_velocity.ks` is the intended follow-on helper after `intercept.ks` to reduce relative speed at closest approach.
- `kos/set_intercept.ks` remains as a compatibility alias for older procedures and forwards into `intercept`.
- The craft currently uses large docking ports, while `kOS-MunTug` uses a standard docking port.
- Add a docking adapter path in the VAB (or a standard port on the station) before mixed-diameter docking operations.
- Add dedicated comms relay hardware and RCS translation authority in the VAB if this vehicle will act as an autonomous station assembly hub.
