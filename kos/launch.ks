// Basic kOS ascent and circularization script for the Mun tug launcher.

set targetApoapsis to 80000.
set targetPeriapsis to targetApoapsis - 2000.
set turnStartAltitude to 250.
set turnEndAltitude to 45000.
set pitchChangeAmount to 80.

sas off.
rcs off.

lock throttle to 1.
lock steering to heading(90, 90).

print "Launching...".
stage.
wait 2.

until ship:apoapsis >= targetApoapsis {
    set frac to (ship:altitude - turnStartAltitude) / (turnEndAltitude - turnStartAltitude).
    if frac < 0 { set frac to 0. }.
    if frac > 1 { set frac to 1. }.

    set pitch to 90 - (pitchChangeAmount * frac).
    lock steering to heading(90, pitch).

    if ship:apoapsis > targetApoapsis * 0.9 {
        lock throttle to 0.35.
    }.

    wait 0.1.
}.

lock throttle to 0.
print "Apoapsis target reached.".

// Separate from launcher stage if present.
stage.

wait until eta:apoapsis < 30.
lock steering to prograde.
lock throttle to 1.

wait until ship:periapsis >= targetPeriapsis.
lock throttle to 0.

print "Orbit established near 80 km.".
