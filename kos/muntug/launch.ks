// Very simple "good enough" ascent + circularize helper.
// Tune numbers for your rocket.

clearscreen.
print "kOS Launch Script".

set targetApo to 80000. // 80 km
set turnStart to 2000.  // start turning at 2 km
set turnEnd to 45000.   // finish turn by 45 km

sas off.
rcs off.

print "Launching...".
lock throttle to 1.
stage.

until ship:apoapsis > targetApo {

  if ship:altitude > turnStart {
    set frac to (ship:altitude - turnStart) / (turnEnd - turnStart).
    if frac > 1 { set frac to 1. }.
    if frac < 0 { set frac to 0. }.

    set pitch to 90 - (80 * frac). // 90 -> ~10 deg
    lock steering to heading(90, pitch).
  } else {
    lock steering to heading(90, 90).
  }.

  wait 0.1.
}.

print "Coast to apoapsis...".
lock throttle to 0.

until eta:apoapsis < 20 { wait 0.5. }.

print "Circularizing...".
lock steering to prograde.
lock throttle to 0.7.

until ship:periapsis > 75000 { wait 0.1. }.

lock throttle to 0.
print "Orbit achieved.".

print "Docking prep: RCS ON, SAS ON".
rcs on.
sas on.