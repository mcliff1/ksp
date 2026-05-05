# kOS Script Review

Date: 2026-05-04

## Scope

Reviewed these scripts:

- `kos/launch.ks`
- `kos/muntug/circle.ks`
- `kos/muntug/circle1.ks`
- `kos/muntug/exlaunch.ks`
- `kos/muntug/intercept.ks`
- `kos/muntug/intercept1.ks`
- `kos/muntug/intercept2.ks`
- `kos/muntug/launch.ks`
- `kos/muntug/launch1a.ks`
- `kos/muntug/match1.ks`
- `kos/muntug/orbit.ks`

This review is static only. I did not run the scripts inside KSP/kOS from this environment.

## Executive Summary

The repository currently has one clearly primary mission script and a second group of MunTug helper scripts that look like iterative prototypes. The safest current baseline is `kos/launch.ks`. Inside `kos/muntug/`, a few helpers look usable with care, but several files are older experiments with obvious breakage.

Recommended keep/use set:

- `kos/launch.ks`
- `kos/muntug/circle1.ks`
- `kos/muntug/intercept2.ks`
- `kos/muntug/match1.ks`
- `kos/muntug/orbit.ks`

Recommended archive or ignore for now:

- `kos/muntug/circle.ks`
- `kos/muntug/exlaunch.ks`
- `kos/muntug/intercept1.ks`

Needs manual validation before trusting on a real launch:

- `kos/muntug/launch.ks`
- `kos/muntug/launch1a.ks`
- `kos/muntug/intercept.ks`

## Overall Assessment

The root-level `kos/launch.ks` is the most coherent script in the repo. It matches the mission described in `project.md`: ascent to parking orbit, waiting for a Mun transfer window, transfer injection, optional Mun capture, and return guidance.

The `kos/muntug/` folder looks like a workbench of smaller task-specific scripts and multiple generations of the same idea. In practice, it contains:

- one better circularization script (`circle1.ks`)
- one better intercept script (`intercept2.ks`)
- useful rendezvous helpers (`match1.ks`, `orbit.ks`)
- several draft or superseded variants that should not be treated as production scripts

## Script-by-Script Notes

### `kos/launch.ks`

Status: best current script

What it does:

- launches to about 80 km x 78 km parking orbit
- waits for a Mun transfer phase angle
- performs a simple trans-Mun injection by raising apoapsis near Mun orbit
- optionally captures at the Mun
- prints return guidance

Strengths:

- complete mission flow in one file
- readable structure with helper functions
- clear timeouts for transfer-window wait and Mun coast

Risks:

- assumes the craft and staging layout match the current launcher exactly
- injection is simplified to an apoapsis target rather than a proper maneuver-node solution
- phase angle uses a raw angle between ship and Mun position vectors, which is simple but may need in-game tuning

Recommendation:

- treat this as the main script to keep improving

### `kos/muntug/launch.ks`

Status: simple helper, probably usable

What it does:

- basic ascent to 80 km apoapsis
- simple circularization burn to about 75 km periapsis
- enables RCS and SAS at the end

Strengths:

- short and easy to reason about
- good as a quick launcher smoke test

Risks:

- no auto-staging beyond the initial `stage.`
- no flameout handling
- tuned for a generic rocket, not specifically the current MunTug launcher

Recommendation:

- keep as a basic LKO test script, not as the main mission automation

### `kos/muntug/launch1a.ks`

Status: promising prototype, not yet trustworthy

What it does:

- launches to 100 km
- performs a gradual gravity turn
- attempts engine flameout staging during ascent and circularization

Strengths:

- more complete ascent logic than `kos/muntug/launch.ks`
- includes mid-burn staging support

Risks:

- the liftoff block uses `UNTIL SHIP:MAXTHRUST > 0 { STAGE. }`, which can rapidly fire stages until thrust appears
- the gravity-turn logic is altitude-only and may not suit the current craft mass or drag profile
- there is no explicit protection against staging away needed transfer hardware

Recommendation:

- keep only if you want to repair and test it in KSP; otherwise prefer `kos/launch.ks`

### `kos/muntug/exlaunch.ks`

Status: broken draft

What it does:

- older launch script with a countdown, pitch schedule, and automatic staging trigger

Blocking issues:

- it uses `WHEN MAXTHRUST = 0 THEN { ... }`, which is suspicious and likely invalid because the rest of the repo consistently uses `SHIP:MAXTHRUST`
- even if corrected, a `WHEN ... PRESERVE` auto-stage trigger on zero thrust is fragile and can misfire through staging transitions

Other issues:

- no circularization logic after reaching target apoapsis
- older style and comments suggest this is an experiment rather than a maintained script

Recommendation:

- do not use this without rewriting it

### `kos/muntug/circle1.ks`

Status: best circularization helper

What it does:

- accepts a target point parameter (`APO` or `PERI`)
- computes required circularization delta-v
- creates a maneuver node
- aligns to the node and executes the burn with throttle tapering and flameout staging

Strengths:

- internally consistent
- clearly the cleaned-up version of `circle.ks`
- good standalone utility for orbit cleanup

Risks:

- assumes `SHIP:MAXTHRUST / SHIP:MASS` is a good enough burn-time estimate
- still needs in-game validation for kOS syntax and maneuver-node behavior on your installed version

Recommendation:

- keep as the circularization utility to build on

### `kos/muntug/circle.ks`

Status: broken / superseded

What it does:

- attempts the same job as `circle1.ks`

Blocking issues:

- it references `point_to_circ` even though the only assignment is commented out
- it mixes two mutually exclusive approaches: string-based `mode` handling and older `point_to_circ` handling
- the variable `r` is set correctly once, then overwritten by the stale branch

Recommendation:

- archive this file and use `circle1.ks` instead

### `kos/muntug/intercept2.ks`

Status: best intercept helper

What it does:

- checks for a selected target
- computes a Hohmann-style transfer phase angle
- waits for the correct phase window
- performs a prograde transfer burn with simple throttle tapering

Strengths:

- cleaner than the other intercept variants
- current-phase helper is more explicit than the earlier versions
- best candidate if you want a reusable rendezvous transfer helper

Risks:

- this is still a simplified coplanar transfer script, not a robust general rendezvous planner
- it assumes the target is orbiting the same central body and ignores plane changes and node planning

Recommendation:

- keep as the intercept prototype to refine

### `kos/muntug/intercept.ks`

Status: older variant, maybe usable after cleanup

What it does:

- similar to `intercept2.ks`, but with a different target check and phase-angle implementation

Issues:

- `IF NOT (DEFINED TARGET) OR TARGET = "None"` is brittle; comparing `TARGET` to a string is probably unnecessary and may not behave as intended
- it uses `TARGET:BODY` for `mu`, which is only correct if that suffix resolves to the same central body you are orbiting

Recommendation:

- if you keep one intercept helper, keep `intercept2.ks` instead of this file

### `kos/muntug/intercept1.ks`

Status: broken draft

What it does:

- earlier intercept helper variant

Blocking issues:

- the first guard is `IF NOT (HAGT)`, which looks like a typo or broken placeholder and is not consistent with any other script in the repo

Recommendation:

- do not use this file; replace with `intercept2.ks`

### `kos/muntug/match1.ks`

Status: useful helper

What it does:

- waits for close approach to the current target
- points at relative retrograde
- burns until relative orbital-frame velocity is near zero

Strengths:

- simple and focused
- reasonable utility after a transfer or close approach

Risks:

- uses orbital-frame relative velocity, which is a simplification
- no timeout or fuel checks

Recommendation:

- keep as a practical rendezvous helper

### `kos/muntug/orbit.ks`

Status: usable prototype

What it does:

- raises or lowers orbit to a requested altitude
- coasts to apoapsis or periapsis
- circularizes with a second burn

Strengths:

- useful utility script for simple orbit changes
- easy to understand and extend

Risks:

- computes `dv_burn` but does not actually use it for timing or cutoff
- no stage handling if the active engine flames out during either burn
- burn logic is open-loop and depends on orbital suffixes updating cleanly during full-throttle flight

Recommendation:

- keep, but treat it as a helper that still needs flight testing

## Suggested Cleanup

If the goal is to keep only the most useful scripts from the imported mac environment, the cleanest reduced set is:

- `kos/launch.ks` as the primary launcher and Mun transfer script
- `kos/muntug/circle1.ks` for circularization
- `kos/muntug/intercept2.ks` for transfer/intercept timing
- `kos/muntug/match1.ks` for relative velocity matching
- `kos/muntug/orbit.ks` for simple orbit adjustments

Everything else currently reads like a draft, experiment, or superseded version.

## Suggested Next Step

The next practical step is to run a short in-KSP validation pass in this order:

1. `kos/launch.ks`
2. `kos/muntug/circle1.ks`
3. `kos/muntug/intercept2.ks`
4. `kos/muntug/match1.ks`
5. `kos/muntug/orbit.ks`

That will tell you quickly whether the remaining issues are only tuning problems or whether any of the kept scripts still have kOS syntax/runtime errors on your installed version.