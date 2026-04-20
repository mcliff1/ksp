# Mun Orbital Intercept Test Mission

## Mission intent

These craft and scripts support a stock KSP 1.12.5 mission to validate a robotic Mun transfer profile, achieve a controlled intercept around the Mun, preserve enough delta-v for either Mun orbit insertion or a free-return pass, and return the tug to Kerbin space.

The immediate test objective is not crew transport or landing. The objective is to prove that the launcher can deliver the tug to a stable Kerbin parking orbit with enough remaining propulsion margin to:

- perform a trans-Mun injection
- target a low Mun periapsis for orbital intercept testing
- either capture into low Mun orbit or continue on a free-return trajectory
- reserve enough propellant for the Kerbin return leg and small correction burns

## Vehicle configuration requirements

### Tug requirements

The Mun tug stack is the mission payload and must retain these parts from the `kos-test.craft` baseline:

- `dockingPort2`
- `HECS2.ProbeCore`
- `kOSMachine1m`
- `RCSFuelTank`
- `fuelTank` (`FL-T800`)
- `fuelTankSmall` (`FL-T400`)
- `liquidEngine3.v2` (`Terrier`)
- `RCSBlock.v2`

The tug is expected to provide roughly 4.6 km/s vacuum delta-v when launched full. That is sufficient for a Mun transfer, Mun-space corrections, and Kerbin return only if the launcher performs the majority of ascent work.

### Launcher requirements

The launcher stage must satisfy all of the following:

- the lower-stage engine must have a valid propellant path at ignition
- the launcher must provide meaningful ascent delta-v without consuming most of the tug's mission propellant
- lift-off thrust-to-weight ratio should remain above about 1.15
- the atmospheric stack must be laterally stable enough for a scripted gravity turn

For this mission profile, the launcher should use:

- `liquidEngine2.v2` (`Swivel`) as the first-stage engine
- `Decoupler.1` between the launcher and the tug
- dedicated lower-stage `fuelTank` parts below the decoupler
- a symmetric fin set on the lower stage

## Mission profile requirements

### Phase 1: launch and parking orbit

Target parking orbit:

- apoapsis: about 80 km
- periapsis: about 78 km to 80 km

Ascent guidance requirements:

- use a conservative gravity turn to limit drag and steering loss
- avoid consuming excessive Terrier propellant before circularization
- stage the lower launcher cleanly before Terrier-only flight

### Phase 2: trans-Mun injection

Transfer requirements:

- depart from a low Kerbin orbit near a standard Mun transfer window
- target a Kerbin apoapsis near the Mun orbital radius
- aim for a Mun periapsis in the range of about 15 km to 30 km
- preserve correction margin after the injection burn

Nominal transfer window:

- the Mun should lead the spacecraft by about 44 degrees in Kerbin orbit at injection

### Phase 3: Mun orbital intercept test

Primary success criteria:

- enter Mun sphere of influence on a controlled approach
- achieve a predictable low periapsis around the Mun
- validate that the tug has enough remaining delta-v to either capture or safely return

Two acceptable mission modes:

1. Free-return intercept test

- perform a close Mun flyby without full capture
- use the encounter to validate navigation, timing, and return geometry

2. Mun orbit insertion test

- burn near Mun periapsis to capture into a low orbit
- recommended initial capture orbit: about 15 km x 25 km or similar
- retain enough propellant for trans-Kerbin injection afterward

### Phase 4: Kerbin return

Return requirements:

- if on free-return, correct Kerbin periapsis into a safe reentry corridor
- if captured at the Mun, execute a departure burn that lowers Kerbin periapsis into the atmosphere
- target Kerbin periapsis for return: about 30 km to 40 km

## Delta-v planning guidance

Planning values for a stock-style mission:

- launch to LKO: about 3400 m/s total vehicle delta-v requirement
- trans-Mun injection from LKO: about 850 m/s to 900 m/s
- small mid-course correction budget: about 50 m/s to 150 m/s
- Mun orbit insertion, if performed: about 250 m/s to 350 m/s depending on approach
- trans-Kerbin injection from low Mun orbit: about 300 m/s to 350 m/s
- final correction and reentry targeting reserve: about 100 m/s to 150 m/s

Operational rule:

- do not spend the tug's deep-space reserve solving a launcher deficiency

## kOS automation requirements

The mission script should support these functions:

- automated launch and parking orbit insertion
- staging logic that cleanly separates lower stage and tug
- transfer-window handling or transfer-window guidance
- trans-Mun injection guidance
- Mun intercept monitoring and periapsis management guidance
- Kerbin return guidance or at minimum clear return-burn criteria

The script does not need to solve docking, landing, or precision science operations.

## Validation checklist

- craft loads in VAB on KSP 1.12.5 with kOS 1.5.1
- launcher first stage ignites with available propellant
- launcher remains controllable through max-q
- tug reaches parking orbit with substantial remaining LF/Ox
- mission can achieve a Mun intercept with return margin still available
- script behavior is understandable enough to debug from the kOS terminal