// Relative-velocity matching helper for rendezvous.
// Works with any craft that can produce forward thrust.
// Select a target in map view before running.

clearscreen.

set closeApproachDistance to 5000.
set maxWaitTime to 21600.
set highSpeedThrottle to 1.0.
set mediumSpeedThrottle to 0.2.
set lowSpeedThrottle to 0.05.
set highSpeedThreshold to 50.
set mediumSpeedThreshold to 5.
set targetRelativeSpeed to 0.1.
set alignTolerance to 2.

function cleanup_and_exit {
    parameter message.
    print message.
    lock throttle to 0.
    unlock steering.
    unlock throttle.
    set ship:control:pilotmainthrottle to 0.
    exit.
}.

if not hastarget {
    cleanup_and_exit("CRITICAL: No target selected in map view.").
}.

if target:body:name <> ship:body:name {
    cleanup_and_exit("CRITICAL: Target is not orbiting the same body.").
}.

if ship:availablethrust <= 0 {
    cleanup_and_exit("CRITICAL: No available thrust. Enable an engine or switch to manual RCS match.").
}.

set targetVessel to target.
set waitStart to time:seconds.
set lastDistance to (targetVessel:position - ship:position):mag.

print "Matching velocity with: " + targetVessel:name.
print "Waiting for closest approach...".

until lastDistance < closeApproachDistance {
    if time:seconds - waitStart > maxWaitTime {
        cleanup_and_exit("Timed out waiting for closest approach.").
    }.

    set currentDistance to (targetVessel:position - ship:position):mag.

    if currentDistance > lastDistance {
        print "Distance started increasing; beginning velocity match now.".
        break.
    }.

    set lastDistance to currentDistance.
    wait 0.1.
}.

lock relativeVelocity to ship:velocity:orbit - targetVessel:velocity:orbit.
lock steering to lookdirup(-relativeVelocity, ship:up:vector).

print "Aligning to relative retrograde...".
wait until vang(ship:facing:vector, -relativeVelocity) < alignTolerance.

print "Zeroing relative velocity...".
until relativeVelocity:mag < targetRelativeSpeed {
    if relativeVelocity:mag > highSpeedThreshold {
        lock throttle to highSpeedThrottle.
    } else if relativeVelocity:mag > mediumSpeedThreshold {
        lock throttle to mediumSpeedThrottle.
    } else {
        lock throttle to lowSpeedThrottle.
    }.

    print "Relative speed: " + round(relativeVelocity:mag, 2) + " m/s   " at (0, 10).
    wait 0.1.
}.

lock throttle to 0.
unlock steering.
unlock throttle.
set ship:control:pilotmainthrottle to 0.

print "Velocity match complete.".
