# AGENTS

## How crafts were generated/updated

- Source of truth is `kos-test.craft` in repository root.
- `craft/kOS-MunTug-Launcher.craft` is derived directly from `kos-test.craft` with launcher parts retained.
- `craft/kOS-MunTug.craft` is derived from `kos-test.craft` by removing launcher-only parts:
  - `Decoupler.1`
  - `liquidEngine2.v2`
  - `basicFin`
- Tug craft keeps the requested parts: `dockingPort2`, `HECS2.ProbeCore`, `kOSMachine1m`, `RCSFuelTank`, `fuelTank`, `fuelTankSmall`, `liquidEngine3.v2`, and `RCSBlock.v2`.
- Attachments were preserved from source where valid; launcher-only references were removed in tug craft.

## KSP testing checklist

- [ ] Craft files copied to `KSP/saves/<save>/Ships/VAB/`
- [ ] `kOS-MunTug.craft` loads in VAB without missing-part warnings
- [ ] `kOS-MunTug-Launcher.craft` loads in VAB without missing-part warnings
- [ ] Launcher staging order verified:
  - [ ] Lifter engine ignition stage first
  - [ ] Decouple tug from launcher stage second
  - [ ] Tug engine stage last
- [ ] RCS control and translation confirmed in flight
- [ ] `launch.ks` runs without syntax/runtime errors
- [ ] Ascent reaches ~80 km apoapsis and circularizes near 80 km periapsis
