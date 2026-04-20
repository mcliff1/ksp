# Contributor Notes

## How these craft files were generated

- Source of truth is `kos-test.craft` in this repository.
- `craft/kOS-MunTug-Launcher.craft` was originally derived from that baseline, but the current launcher has since been updated in the KSP UI and now includes additional power, comms, RCS, and launcher parts beyond the original minimal reference craft.
- `craft/kOS-MunTug.craft` is derived from the same baseline with launcher parts removed while keeping tug parts:
  - `dockingPort2`
  - `HECS2.ProbeCore`
  - `kOSMachine1m`
  - `RCSFuelTank`
  - `fuelTank` (FL-T800)
  - `fuelTankSmall` (FL-T400)
  - `liquidEngine3.v2` (Terrier)
  - `RCSBlock.v2` (4-way RCS block)

## Current launcher-specific notes

- The current `craft/kOS-MunTug-Launcher.craft` contains these launcher/service additions that are not represented in `kos-test.craft`:
  - `batteryBank`
  - 4x `solarPanels5`
  - `HighGainAntenna5.v2`
  - extra `RCSBlock.v2` units
  - a second FL-T800 in the lower boost stack
  - a 4-fin lower-stage layout
- The lower decoupler above the boost stack currently has crossfeed enabled in the launcher craft.
- The upper decoupler between the tug bus and the FL-T400 / Terrier segment currently has crossfeed disabled and should be reviewed carefully in KSP staging to ensure the final vehicle keeps its transfer engine.

## Safe update process

1. Update `kos-test.craft` in KSP first.
2. If launcher-only changes were made directly in the UI, record those differences before assuming `kos-test.craft` still matches the launcher.
3. Derive/refresh both craft files from that updated baseline.
4. Do not hand-edit random module values unless required; preserve KSP-authored blocks whenever possible.
5. Keep part internal names exactly as exported by KSP/kOS.
6. Keep this repository stock + kOS only (no Breaking Ground DLC dependencies).

## In-KSP testing checklist

- [ ] KSP version is 1.12.5.
- [ ] kOS version is 1.5.1.
- [ ] `kOS-MunTug.craft` loads in VAB without missing parts.
- [ ] `kOS-MunTug-Launcher.craft` loads in VAB without missing parts.
- [ ] Full launcher staging is sensible and leaves the final spacecraft with its Terrier-powered transfer stage attached.
- [ ] Launcher has battery storage, solar generation, and 4 lower fins.
- [ ] Tug has docking port, HECS2, kOS CPU, monoprop tank, Terrier, FL-T400, and the intended RCS / comms hardware.
- [ ] `launch.ks` can be run from the kOS terminal.
