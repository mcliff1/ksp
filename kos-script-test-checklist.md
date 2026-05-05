# kOS Script Test Checklist

Date: 2026-05-04

## Purpose

This checklist turns the script review into an in-KSP validation pass. The goal is to verify which kept scripts actually run under KSP 1.12.5 with kOS 1.5.1 and which ones still need repair or retuning.

Primary scripts under test:

- `kos/launch.ks`
- `kos/muntug/circle1.ks`
- `kos/muntug/intercept2.ks`
- `kos/muntug/match1.ks`
- `kos/muntug/orbit.ks`

## Test Environment

Required environment:

- KSP 1.12.5
- kOS 1.5.1
- stock parts only
- `craft/kOS-MunTug-Launcher.craft` for launch tests
- `craft/kOS-MunTug.craft` for orbit and rendezvous helper tests when practical

Before any script test, verify these craft conditions in the VAB:

- lower launcher decoupler above the boost stack has crossfeed enabled
- upper decoupler between tug bus and FL-T400/Terrier segment is staged correctly and will not strand the probe bus without the Terrier
- launcher has battery, solar panels, antenna, and four lower fins
- the kOS CPU can see the scripts on the selected volume

Suggested script install layout:

- copy the root launcher script as `0:/launch.ks`
- copy helper scripts as `0:/muntug/circle1.ks`, `0:/muntug/intercept2.ks`, `0:/muntug/match1.ks`, and `0:/muntug/orbit.ks`

## What To Record

For every run, record these items:

- craft used
- launch mass if visible
- remaining LF/Ox after the script finishes
- terminal output near failure or completion
- apoapsis and periapsis after burn completion
- whether staging removed any required tug hardware
- whether the script stopped cleanly, hung, or threw a kOS error

## Test 1: Main Mission Script

Script: `run launch.`

Craft:

- `craft/kOS-MunTug-Launcher.craft`

Goal:

- verify the main script can launch, park in LKO, wait for a Mun window, inject, and at least coast toward a Mun encounter without obvious staging loss

Setup:

- start on the launchpad
- SAS off, RCS off
- confirm staging shows first-stage ignition, lower-stage separation, then Terrier/tug transfer stage retained
- make sure the terminal can access `launch.ks`

Pass sequence:

1. Run `run launch.`
2. Watch for these messages:
   - `Launching to parking orbit...`
   - `Apoapsis target reached; staging launcher.`
   - `Parking orbit established near 80 km.`
   - `Waiting for Mun transfer window...`
3. In map view, confirm parking orbit is about 80 km x 78 km or better.
4. When transfer starts, confirm the Terrier stage is still attached to the tug bus.
5. Watch for either:
   - `Entered Mun sphere of influence.`
   - or timeout/abort text that explains why the transfer failed

Pass criteria:

- reaches a stable Kerbin parking orbit near 80 km
- staging leaves the tug with its Terrier and transfer fuel attached
- performs a transfer burn instead of hanging in orbit indefinitely
- either reaches Mun SOI or exits with a clear timeout message

Failure signs:

- lower stage fails to ignite or runs dry immediately
- upper decoupler fires and leaves the probe bus without the engine section
- circularization burns too long and wastes deep-space fuel
- waits forever for phase angle without converging to a transfer
- script throws a kOS syntax or runtime error

Notes to capture:

- fuel remaining when parking orbit is achieved
- Mun periapsis if an encounter appears
- whether free-return geometry looks plausible

## Test 2: Circularization Helper

Script:

- `runpath("0:/muntug/circle1").`
- or `runpath("0:/muntug/circle1", "APO").`

Craft:

- any vessel already in an eccentric Kerbin orbit
- preferably the MunTug or a simple test craft with a maneuver-capable engine

Goal:

- verify node creation, burn alignment, and cutoff logic

Setup:

- establish an orbit with a visibly different apoapsis and periapsis
- make sure enough fuel remains for one short burn

Pass sequence:

1. At or before apoapsis, run the script with `APO`.
2. Confirm a maneuver node is created automatically.
3. Confirm the vessel points at the node burn vector.
4. Confirm throttle starts near the burn window and drops near the end.
5. Confirm the node is removed after completion.

Pass criteria:

- node appears without syntax error
- ship turns to the burn vector and executes the burn
- final orbit is substantially more circular than the starting orbit
- script exits cleanly

Failure signs:

- node not created
- ship never finishes aligning
- burn starts at the wrong time and misses the node badly
- staging triggers unexpectedly during a single-stage burn

Notes to capture:

- starting and ending apoapsis/periapsis
- whether `DECLARE PARAMETER` syntax is accepted by your kOS install

## Test 3: Orbit Raise/Lower Helper

Script:

- `runpath("0:/muntug/orbit", 120000).`

Craft:

- vessel already in stable Kerbin orbit

Goal:

- verify the script can raise or lower orbit in two burns without hanging

Setup:

- start from a nearly circular orbit around 80 km to 100 km
- choose a target clearly different from the current orbit, such as 120 km

Pass sequence:

1. Run the script with a target altitude above current apoapsis.
2. Confirm it prints `Phase 1: Raising Apoapsis...` or the lowering equivalent.
3. Confirm it performs a first burn, coasts, then performs a second circularization burn.
4. Check final orbit in map view.

Pass criteria:

- both burns happen
- final orbit is close to requested altitude
- script stops cleanly without manual intervention

Failure signs:

- ship points correctly but never throttles down
- coasting phase never resumes into burn two
- final orbit remains highly eccentric

Notes to capture:

- requested target altitude
- final apoapsis/periapsis
- whether the open-loop burn cutoff is close enough to keep

## Test 4: Intercept Helper

Script:

- `runpath("0:/muntug/intercept2").`

Craft:

- vessel in orbit around the same body as the selected target
- start with a simple Kerbin-orbit target rather than the Mun for the first validation pass

Goal:

- verify target detection, phase-angle wait, and burn execution

Setup:

- place a target vessel in a similar circular orbit around Kerbin
- select that vessel as target in map view before running the script

Pass sequence:

1. Select the target.
2. Run `runpath("0:/muntug/intercept2").`
3. Confirm the terminal prints the target name and required phase angle.
4. Watch warp behavior while it waits for the window.
5. Confirm it aligns prograde and performs a transfer burn.

Pass criteria:

- recognizes the selected target
- computes a phase angle and waits instead of erroring out
- exits warp and performs a burn at the correct time

Failure signs:

- immediate target error despite a target being selected
- phase angle display never stabilizes or clearly normalizes wrong
- burn happens but encounter distance gets worse instead of better

Notes to capture:

- starting altitude of both vessels
- closest-approach distance before and after the burn
- whether warp handling behaves safely

## Test 5: Velocity Match Helper

Script:

- `runpath("0:/muntug/match1").`

Craft:

- active vessel on approach to a target vessel

Goal:

- verify that the script can kill relative velocity near closest approach without oscillating badly

Setup:

- create a modest close approach first, ideally within a few kilometers
- select the target in map view
- make sure RCS or a low-thrust engine is available

Pass sequence:

1. Start from an intercept where relative speed is non-zero.
2. Run the script before closest approach.
3. Confirm it waits while distance is still decreasing.
4. Confirm it points to relative retrograde.
5. Confirm relative speed trends toward zero.

Pass criteria:

- script identifies target
- ship turns to the expected direction
- relative speed drops close to zero without large overshoot

Failure signs:

- ship points the wrong way
- relative speed increases during the burn
- the script never exits because `rel_vel:MAG` stops decreasing above the threshold

Notes to capture:

- closest distance at start of burn
- relative speed before and after burn
- whether using engine thrust or RCS gave better control

## Recommended Run Order

Run the validation in this order:

1. `kos/launch.ks`
2. `kos/muntug/circle1.ks`
3. `kos/muntug/orbit.ks`
4. `kos/muntug/intercept2.ks`
5. `kos/muntug/match1.ks`

That order gives you the cheapest failure detection first:

- the main launcher script confirms staging and mission viability
- the orbit helpers validate basic burn control in a safer environment
- the intercept and match helpers come last because they depend on target selection and orbital setup

## Quick Triage Rules

If a script fails, classify it immediately as one of these:

- syntax failure: kOS rejects the script before execution
- environment failure: target, staging, or craft setup was wrong
- tuning failure: script logic runs but guidance or throttle values are poor
- logic failure: script runs but the control flow or math is wrong

That distinction matters because only the last two categories imply the script itself needs code changes.

## Minimal Test Log Template

Use this for each run:

```text
Script:
Craft:
Command run:
Starting orbit or launch state:
Result:
Terminal output summary:
Final orbit:
Fuel remaining:
Staging issue observed:
Next action:
```