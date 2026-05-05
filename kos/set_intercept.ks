// Same-body intercept helper adapted from the latest working MunTug script.
// Select a target in map view before running.

clearscreen.

set phaseTolerance to 1.
set slowWarpPhaseError to 10.
set maxWaitTime to 21600.
set coarseThrottleDelta to 5.
set fineThrottleDelta to 1.
set alignTolerance to 1.
set statusUpdateInterval to 1.

function normalize_angle {
    parameter angleDeg.

    until angleDeg >= 0 {
        set angleDeg to angleDeg + 360.
    }.

    until angleDeg < 360 {
        set angleDeg to angleDeg - 360.
    }.

    return angleDeg.
}.

function shortest_angle_diff {
    parameter fromDeg, toDeg.
    local delta is normalize_angle(toDeg - fromDeg).

    if delta > 180 {
        set delta to delta - 360.
    }.

    return delta.
}.

function current_phase_angle {
    local shipLongitude is ship:orbit:lan + ship:orbit:argumentofperiapsis + ship:orbit:trueanomaly.
    local targetLongitude is target:orbit:lan + target:orbit:argumentofperiapsis + target:orbit:trueanomaly.

    return normalize_angle(targetLongitude - shipLongitude).
}.

function cleanup_and_exit {
    parameter message.
    print message.
    set warp to 1.
    lock throttle to 0.
    unlock steering.
    unlock throttle.
    set ship:control:pilotmainthrottle to 0.
    exit.
}.

sas off.

if not hastarget {
    cleanup_and_exit("CRITICAL: No target selected in map view.").
}.

if target:body:name <> ship:body:name {
    cleanup_and_exit("CRITICAL: Target is not orbiting the same body.").
}.

set mu to ship:body:mu.
set shipRadius to ship:orbit:semimajoraxis.
set targetRadius to target:orbit:semimajoraxis.

if abs(targetRadius - shipRadius) < 1000 {
    cleanup_and_exit("Target orbit is already very close to current orbit.").
}.

set transferSemiMajorAxis to (shipRadius + targetRadius) / 2.
set transferTime to constant:pi * sqrt(transferSemiMajorAxis^3 / mu).
set targetAngularVelocity to sqrt(mu / targetRadius^3).
set targetDegreesDuringTransfer to (targetAngularVelocity * transferTime) * (180 / constant:pi).
set targetPhaseGoal to normalize_angle(180 - targetDegreesDuringTransfer).
set waitStart to time:seconds.
set phaseError to shortest_angle_diff(current_phase_angle(), targetPhaseGoal).

print "Target: " + target:name.
print "Current body: " + ship:body:name.
print "Required phase angle: " + round(targetPhaseGoal, 2).
print "Waiting for phase angle window...".

set warp to 3.
until abs(phaseError) <= phaseTolerance {
    if time:seconds - waitStart > maxWaitTime {
        cleanup_and_exit("Timed out waiting for intercept window.").
    }.

    if abs(phaseError) < slowWarpPhaseError {
        set warp to 0.
    }.

    print "Current phase: " + round(current_phase_angle(), 2) + " / Goal: " + round(targetPhaseGoal, 2) + " / Error: " + round(phaseError, 2) + "   " at (0, 12).
    wait statusUpdateInterval.
    set phaseError to shortest_angle_diff(current_phase_angle(), targetPhaseGoal).
}.
set warp to 0.

set circularVelocity to sqrt(mu / shipRadius).
set transferVelocity to sqrt(mu * (2 / shipRadius - 1 / transferSemiMajorAxis)).
set dv to transferVelocity - circularVelocity.

if abs(dv) < 0.1 {
    cleanup_and_exit("Computed burn is too small for a meaningful intercept.").
}.

if dv >= 0 {
    lock steering to prograde.
    print "Aligning to prograde for intercept burn...".
    wait until vang(ship:facing:vector, prograde:vector) < alignTolerance.
} else {
    lock steering to retrograde.
    print "Aligning to retrograde for intercept burn...".
    wait until vang(ship:facing:vector, retrograde:vector) < alignTolerance.
}.

print "Executing burn: " + round(dv, 2) + " m/s".
lock throttle to 1.
set targetVelocity to ship:velocity:orbit:mag + dv.

if dv >= 0 {
    until ship:velocity:orbit:mag >= targetVelocity {
        if targetVelocity - ship:velocity:orbit:mag < coarseThrottleDelta {
            lock throttle to 0.2.
        }.
        if targetVelocity - ship:velocity:orbit:mag < fineThrottleDelta {
            lock throttle to 0.05.
        }.
        wait 0.1.
    }.
} else {
    until ship:velocity:orbit:mag <= targetVelocity {
        if ship:velocity:orbit:mag - targetVelocity < coarseThrottleDelta {
            lock throttle to 0.2.
        }.
        if ship:velocity:orbit:mag - targetVelocity < fineThrottleDelta {
            lock throttle to 0.05.
        }.
        wait 0.1.
    }.
}.

lock throttle to 0.
unlock steering.
unlock throttle.
set ship:control:pilotmainthrottle to 0.

print "Intercept trajectory established.".
