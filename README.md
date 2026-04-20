# KSP 1.12.5 kOS Mun Tug Crafts

This repo contains stock KSP 1.12.5 craft files built to work with kOS 1.5.1 (no Breaking Ground DLC required).

## Included files

- `craft/kOS-MunTug.craft` — tug-only craft
- `craft/kOS-MunTug-Launcher.craft` — full launcher + tug craft
- `kos/launch.ks` — example kOS launch script

## Install

1. Copy craft files into your save's VAB folder:

   - `craft/kOS-MunTug.craft`
   - `craft/kOS-MunTug-Launcher.craft`

   to:

   - `KSP/saves/<your-save>/Ships/VAB/`

2. Copy `kos/launch.ks` into a kOS-readable volume (for example):

   - `KSP/Ships/Script/launch.ks`

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
