# Contributor Notes

## How these craft files were generated

- Source of truth is `kos-test.craft` in this repository.
- `craft/kOS-MunTug-Launcher.craft` is derived from that baseline and keeps launcher parts (`Decoupler.1`, `liquidEngine2.v2`, `basicFin`) and existing staging order.
- `craft/kOS-MunTug.craft` is derived from the same baseline with launcher parts removed while keeping tug parts:
  - `dockingPort2`
  - `HECS2.ProbeCore`
  - `kOSMachine1m`
  - `RCSFuelTank`
  - `fuelTank` (FL-T800)
  - `fuelTankSmall` (FL-T400)
  - `liquidEngine3.v2` (Terrier)
  - `RCSBlock.v2` (4-way RCS block)

## Safe update process

1. Update `kos-test.craft` in KSP first.
2. Derive/refresh both craft files from that updated baseline.
3. Do not hand-edit random module values unless required; preserve KSP-authored blocks whenever possible.
4. Keep part internal names exactly as exported by KSP/kOS.
5. Keep this repository stock + kOS only (no Breaking Ground DLC dependencies).

## In-KSP testing checklist

- [ ] KSP version is 1.12.5.
- [ ] kOS version is 1.5.1.
- [ ] `kOS-MunTug.craft` loads in VAB without missing parts.
- [ ] `kOS-MunTug-Launcher.craft` loads in VAB without missing parts.
- [ ] Full launcher staging is sensible (Swivel in lower stage, decoupler above it, Terrier/tug above decoupler).
- [ ] Tug has docking port, HECS2, kOS CPU, monoprop tank, Terrier, FL-T800, FL-T400, and 4-way RCS block(s).
- [ ] `launch.ks` can be run from the kOS terminal.
