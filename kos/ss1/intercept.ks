// Same-body intercept helper adapted from the latest working MunTug script.
// Select a target in map view before running.

parameter interceptMode is "NORMAL".

clearscreen.

set phaseTolerance to 1.
set finePhaseTolerance to 0.2.
set slowWarpPhaseError to 10.
set maxWaitTime to 21600.
set phaseLockMaxWait to 180.
set phaseLockSampleStep to 0.2.
set encounterWarpExitDistance to 120000.
set encounterTrimDistance to 25000.
set encounterTrimScale to 0.35.
set encounterTrimMaxDv to 6.
set encounterStatusUpdateInterval to 5.
set autoMatchVelocity to true.
set coarseThrottleDelta to 5.
set fineThrottleDelta to 1.
set alignTolerance to 1.
set statusUpdateInterval to 1.
set burnScale to 1.
set enableTrimPass to false.
set trimDelay to 90.
set trimDvPerDegree to 0.7.
set maxTrimDv to 20.
set matchCloseApproachDistance to 5000.
set matchHighSpeedThreshold to 50.
set matchMediumSpeedThreshold to 5.
set matchHighSpeedThrottle to 1.
set matchMediumSpeedThrottle to 0.2.
set matchLowSpeedThrottle to 0.05.
set matchTargetRelativeSpeed to 0.1.
set matchAlignTolerance to 2.

if interceptMode = "INTERCEPT" or interceptMode = "intercept" {
    set autoMatchVelocity to false.
}.

if interceptMode = "DOCK" or interceptMode = "dock" or interceptMode = "Dock" {
    set phaseTolerance to 0.35.
    set finePhaseTolerance to 0.08.
    set slowWarpPhaseError to 4.
    set burnScale to 1.06.
    set enableTrimPass to true.
    set encounterTrimScale to 0.45.
    set encounterTrimMaxDv to 10.
    set encounterWarpExitDistance to 150000.
    set encounterTrimDistance to 35000.
    set matchTargetRelativeSpeed to 0.05.
}.

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

function clamp {
    parameter value, minValue, maxValue.

    if value < minValue {
        return minValue.
    }.

    if value > maxValue {
        return maxValue.
    }.

    return value.
}.

function burn_delta_v {
    parameter dvCommand.
    local burnDirection is "PROGRADE".

    if abs(dvCommand) < 0.05 {
        print "Trim burn skipped: dV too small.".
        return.
    }.

    if dvCommand >= 0 {
        lock steering to prograde.
        set burnDirection to "PROGRADE".
        wait until vang(ship:facing:vector, prograde:vector) < alignTolerance.
    } else {
        lock steering to retrograde.
        set burnDirection to "RETROGRADE".
        wait until vang(ship:facing:vector, retrograde:vector) < alignTolerance.
    }.

    print "Executing " + burnDirection + " trim burn: " + round(dvCommand, 2) + " m/s".
    lock throttle to 1.
    set targetVelocity to ship:velocity:orbit:mag + dvCommand.

    if dvCommand >= 0 {
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
}.

function coast_to_intercept_and_trim {
    parameter goalPhase.

    print "Coasting toward intercept...".
    set warp to 3.
    set coastStart to time:seconds.
    set lastDistance to (target:position - ship:position):mag.
    set currentDistance to lastDistance.
    set warpExitReason to "UNKNOWN".

    until false {
        if target:body:name <> ship:body:name {
            cleanup_and_exit("Target changed body during coast; aborting.").
        }.

        if time:seconds - coastStart > maxWaitTime {
            cleanup_and_exit("Timed out while coasting toward intercept.").
        }.

        if currentDistance <= encounterWarpExitDistance {
            set warpExitReason to "RANGE_THRESHOLD".
            break.
        }.

        // If range starts increasing, we've crossed closest approach.
        if currentDistance > lastDistance {
            set warpExitReason to "PASSED_CLOSEST_APPROACH".
            break.
        }.

        print "Target range: " + round(currentDistance, 0) + " m   " at (0, 14).
        wait encounterStatusUpdateInterval.
        set lastDistance to currentDistance.
        set currentDistance to (target:position - ship:position):mag.
    }.

    set currentDistance to (target:position - ship:position):mag.

    set warp to 0.
    print "Exited warp for encounter trim. Reason: " + warpExitReason + " | Range: " + round(currentDistance, 0) + " m".

    // If still approaching and not yet near trim distance, coast a bit more.
    set trimWaitStart to time:seconds.
    set lastDistance to currentDistance.
    until currentDistance <= encounterTrimDistance or currentDistance > lastDistance {
        if time:seconds - trimWaitStart > maxWaitTime {
            break.
        }.

        wait 0.5.
        set lastDistance to currentDistance.
        set currentDistance to (target:position - ship:position):mag.
    }.

    set coastPhaseError to shortest_angle_diff(current_phase_angle(), goalPhase).
    set coastTrimDv to clamp(-coastPhaseError * encounterTrimScale, -encounterTrimMaxDv, encounterTrimMaxDv).

    if abs(coastTrimDv) >= 0.1 {
        print "Encounter trim dV: " + round(coastTrimDv, 2) + " m/s from phase error " + round(coastPhaseError, 2) + " deg".
        burn_delta_v(coastTrimDv).
    } else {
        print "Encounter trim skipped: phase error already small (" + round(coastPhaseError, 3) + " deg).".
    }.
}.

function match_velocity_with_target {
    if ship:availablethrust <= 0 {
        cleanup_and_exit("CRITICAL: No available thrust for velocity match.").
    }.

    set targetVessel to target.
    set waitStart to time:seconds.
    set lastDistance to (targetVessel:position - ship:position):mag.

    print "Waiting for closest approach before velocity match...".

    until lastDistance < matchCloseApproachDistance {
        if time:seconds - waitStart > maxWaitTime {
            cleanup_and_exit("Timed out waiting for closest approach.").
        }.

        set currentDistance to (targetVessel:position - ship:position):mag.

        if currentDistance > lastDistance {
            print "Distance increasing; starting velocity match now.".
            break.
        }.

        set lastDistance to currentDistance.
        wait 0.1.
    }.

    lock relativeVelocity to ship:velocity:orbit - targetVessel:velocity:orbit.
    lock steering to lookdirup(-relativeVelocity, ship:up:vector).

    print "Aligning to relative retrograde...".
    wait until vang(ship:facing:vector, -relativeVelocity) < matchAlignTolerance.

    print "Zeroing relative velocity...".
    until relativeVelocity:mag < matchTargetRelativeSpeed {
        if relativeVelocity:mag > matchHighSpeedThreshold {
            lock throttle to matchHighSpeedThrottle.
        } else if relativeVelocity:mag > matchMediumSpeedThreshold {
            lock throttle to matchMediumSpeedThrottle.
        } else {
            lock throttle to matchLowSpeedThrottle.
        }.

        print "Relative speed: " + round(relativeVelocity:mag, 2) + " m/s   " at (0, 10).
        wait 0.1.
    }.

    lock throttle to 0.
    unlock steering.
    unlock throttle.
    set ship:control:pilotmainthrottle to 0.

    print "Velocity match complete.".
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

print "Coarse window reached. Fine phase-locking before burn...".
set phaseLockStart to time:seconds.
set phaseError to shortest_angle_diff(current_phase_angle(), targetPhaseGoal).

until abs(phaseError) <= finePhaseTolerance {
    if time:seconds - phaseLockStart > phaseLockMaxWait {
        print "Fine phase lock timed out; using current phase error: " + round(phaseError, 3) + " deg".
        break.
    }.

    wait phaseLockSampleStep.
    set phaseError to shortest_angle_diff(current_phase_angle(), targetPhaseGoal).
    print "Fine phase error: " + round(phaseError, 3) + " deg   " at (0, 13).
}.

set phaseError to shortest_angle_diff(current_phase_angle(), targetPhaseGoal).
print "Phase lock complete. Burn phase error: " + round(phaseError, 3) + " deg".

set circularVelocity to sqrt(mu / shipRadius).
set transferVelocity to sqrt(mu * (2 / shipRadius - 1 / transferSemiMajorAxis)).
set dv to transferVelocity - circularVelocity.
set dv to dv * burnScale.

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

print "Executing burn: " + round(dv, 2) + " m/s (phase error " + round(phaseError, 3) + " deg)".
burn_delta_v(dv).

if enableTrimPass {
    print "DOCK mode: coasting before trim pass...".
    wait trimDelay.

    set trimPhaseError to shortest_angle_diff(current_phase_angle(), targetPhaseGoal).
    set trimDv to clamp(-trimPhaseError * trimDvPerDegree, -maxTrimDv, maxTrimDv).

    print "DOCK mode trim phase error: " + round(trimPhaseError, 2) + " deg".
    burn_delta_v(trimDv).
}.

coast_to_intercept_and_trim(targetPhaseGoal).

if autoMatchVelocity {
    match_velocity_with_target().
} else {
    print "INTERCEPT mode selected: skipping auto velocity match.".
}.

lock throttle to 0.
unlock steering.
unlock throttle.
set ship:control:pilotmainthrottle to 0.

print "Intercept workflow complete. Mode: " + interceptMode.
